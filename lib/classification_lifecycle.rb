class ClassificationLifecycle
  class ClassificationNotPersisted < StandardError; end

  attr_reader :classification

  def initialize(classification)
    @classification = classification
  end

  def queue(action)
    unless classification.persisted?
      message = "Background process called before persisting the classification."
      raise ClassificationNotPersisted.new(message)
    end
    ClassificationWorker.perform_async(classification.id, action.to_s)
  end

  def transact!(&block)
    Classification.transaction do
      update_classification_data
      #NOTE: ensure the block is evaluated before updating the seen subjects
      # as the count worker won't fire if the seens are set, see #should_count_towards_retirement
      instance_eval(&block) if block_given?
      create_recent
      update_seen_subjects
    end
    publish_data
    #to avoid duplicates in queue, do not refresh the queue before updating seen subjects
    refresh_queue
  end

  def process_project_preference
    if should_create_project_preference?
      upp = UserProjectPreference.where(user: user, project: project).first_or_initialize do |up|
        up.preferences = {}
      end
      if first_classifcation = upp.email_communication.nil?
        Project.increment_counter :classifiers_count, project.id
        upp.email_communication = user.project_email_communication
      end
      upp.changed? ? upp.save! : upp.touch
    end
  end

  def update_seen_subjects
    if should_update_seen? && subjects_are_unseen_by_user?
      UserSeenSubject.add_seen_subjects_for_user(**user_workflow_subject)
      if Panoptes.use_cellect?(workflow)
        subject_ids.each do |subject_id|
          SeenCellectWorker.perform_async(workflow.id, user.try(:id), subject_id)
        end
      end
    end
  end

  def publish_data
    if classification.complete?
      PublishClassificationWorker.perform_async(classification.id)
    end
  end

  def refresh_queue
    subjects_workflow_subject_sets.each do |set_id|
      queue = SubjectQueue.by_set(set_id).find_by(user: user, workflow: workflow)
      if queue && queue.below_minimum?
        EnqueueSubjectQueueWorker.perform_async(queue.id)
      end
    end
  end

  def update_classification_data
    mark_expert_classifier
    add_seen_before_for_user
    add_project_live_state
    add_user_groups
    add_lifecycled_at
    classification.save!
  end

  def mark_expert_classifier
    unseen_gold_std = subjects_are_unseen_by_user? && classification.gold_standard
    expert_user = user && expert_level = project.expert_classifier_level(user)
    if unseen_gold_std && expert_user
      classification.expert_classifier = expert_level
    end
  end

  def subjects_are_unseen_by_user?
    return @unseen if @unseen
    @unseen = !UserSeenSubject.find_by!(user: user, workflow: workflow)
    .try(:subjects_seen?, subject_ids)
  rescue ActiveRecord::RecordNotFound
    @unseen = true
  end

  def should_count_towards_retirement?
    if !classification.complete? || classification.seen_before?
      false
    else
      classification.anonymous? || subjects_are_unseen_by_user?
    end
  end

  def add_project_live_state
    update_classification_metadata(:live_project, project.live)
  end

  def add_user_groups
    return if classification.anonymous?
    update_classification_metadata(:user_group_ids, user.non_identity_user_group_ids)
  end

  def add_lifecycled_at
    classification.lifecycled_at = Time.zone.now
  end

  def add_seen_before_for_user
    if should_update_seen? && !subjects_are_unseen_by_user?
      update_classification_metadata(:seen_before, true)
    end
  end

  private

  def create_recent
    if should_update_seen? && subjects_are_unseen_by_user?
      Recent.create_from_classification(classification)
    end
  end

  def should_update_seen?
    !classification.anonymous? && classification.complete?
  end

  def should_create_project_preference?
    !classification.anonymous?
  end

  def user
    @user ||= classification.user
  end

  def workflow
    @workflow ||= classification.workflow
  end

  def project
    @project ||= classification.project
  end

  def subject_ids
    @subject_ids ||= classification.subject_ids
  end

  def user_workflow_subject
    @user_workflow_subject ||= {
      user: user,
      workflow: workflow,
      subject_ids: subject_ids
    }
  end

  def update_classification_metadata(key, value)
    updated_metadata = classification.metadata.merge(key => value)
    classification.metadata = updated_metadata
  end

  def set_member_subjects
    SetMemberSubject.by_subject_workflow(subject_ids, workflow.id)
  end

  def subjects_workflow_subject_sets
    @subjects_workflow_subject_sets ||= if workflow.grouped
      set_member_subjects.map(&:subject_set_id).uniq
    else
      [nil]
    end
  end
end

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
    dequeue_for_non_logged_in
    Classification.transaction do
      update_classification_data
      #NOTE: ensure the block is evaluated before updating the seen subjects
      # as the count worker won't fire if the seens are set, see #should_count_towards_retirement
      instance_eval(&block) if block_given?
      create_recent
      update_seen_subjects
      publish_to_kafka
      save_to_cassandra unless Rails.env == 'production'
    end
    #to avoid duplicates in queue, do not refresh the queue before updating seen subjects
    refresh_queue
  end

  def process_project_preference
    if should_create_project_preference?
      existing_record = true
      upp = UserProjectPreference.where(user: user, project: project).first_or_create do |up|
        up.email_communication = user.project_email_communication
        up.preferences = {}
        existing_record = false
      end
      upp.touch if existing_record
    end
  end

  def update_seen_subjects
    if should_update_seen? && subjects_are_unseen_by_user?
      UserSeenSubject.add_seen_subjects_for_user(**user_workflow_subject)
    end
  end

  def refresh_queue
    subjects_workflow_subject_sets.each do |set_id|
      if below_threshold_queue?(set_id)
        EnqueueSubjectQueueWorker.perform_async(workflow.id, user.try(:id), set_id)
      end
    end
  end

  def dequeue_for_non_logged_in
    unless user
      sms_ids = set_member_subjects.pluck(:id)
      subjects_workflow_subject_sets.each do |set_id|
        DequeueSubjectQueueWorker.perform_async(workflow.id, sms_ids, nil, set_id)
      end
    end
  end

  def publish_to_kafka
    return unless classification.complete?
    classification_json = KafkaClassificationSerializer.serialize(classification, include: ['subjects']).to_json
    MultiKafkaProducer.publish('classifications', [classification.project.id, classification_json])
  end

  def save_to_cassandra
    return unless classification.complete?
    Cassandra::Classification.from_ar_model(classification)
  end

  def update_classification_data
    mark_expert_classifier
    add_seen_before_for_user
    add_project_live_state
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

  def below_threshold_queue?(set_id)
    if subject_queue = SubjectQueue.by_set(set_id).find_by(user: user, workflow: workflow)
      subject_queue.below_minimum?
    else
      false
    end
  end
end

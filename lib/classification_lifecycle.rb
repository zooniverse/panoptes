class ClassificationLifecycle
  class ClassificationNotPersisted < StandardError; end
  class InvalidAction < StandardError; end

  def self.queue(classification, action)
    unless classification.persisted?
      message = "Background process called before persisting the classification."
      raise ClassificationNotPersisted.new(message)
    end
    ClassificationWorker.perform_async(classification.id, action.to_s)
  end

  def self.perform(classification, action)
    raise InvalidAction unless %w(create update).include?(action)
    ClassificationLifecycle.new(classification, action).execute
  end

  attr_reader :classification, :action

  def initialize(classification, action)
    @classification = classification
    @action = action
  end

  def execute
    return if create? && classification.lifecycled_at.present?

    update_classification_data

    classification.save!

    queue_associated_workers

    # Save the lifecycled_at attribute after queuing the workers as
    # any background job scheduling failures (e.g redis failue)
    # will be handled by re-running this job via RequeueClassificationsWorker
    mark_classification_lifecycled_at
  end

  # fan out workers to deal with the associated data models and services
  def queue_associated_workers
    process_project_preference
    create_recent
    update_seen_subjects
    notify_subject_selector
    update_counters
    publish_data
  end

  def update_classification_data
    mark_expert_classifier
    add_seen_before_for_user
    add_project_live_state
    add_user_groups
  end

  def update_counters
    return unless should_count_towards_retirement?

    classification.subject_ids.each do |sid|
      ClassificationCountWorker.perform_async(sid, classification.workflow.id, update?)
    end
  end

  def process_project_preference
    if should_create_project_preference?
      UserProjectPreferencesWorker.perform_async(user.id, project.id)
    end
  end

  def create_recent
    if should_update_seen? && subjects_are_unseen_by_user?
      RecentCreateWorker.perform_async(classification.id)
    end
  end

  def update_seen_subjects
    if should_update_seen? && subjects_are_unseen_by_user?
      UserSeenSubjectsWorker.perform_async(user.id, workflow.id, subject_ids)
    end
  end

  def publish_data
    return unless classification.complete?

    PublishClassificationWorker.perform_async(classification.id)
  end

  def notify_subject_selector
    return unless should_update_seen?
    return unless subjects_are_unseen_by_user?

    subject_ids.each do |subject_id|
      NotifySubjectSelectorOfSeenWorker.perform_async(workflow.id, user.try(:id), subject_id)
    end
  end

  def mark_expert_classifier
    unseen_gold_std = subjects_are_unseen_by_user? && classification.gold_standard
    expert_user = user && expert_level = project.expert_classifier_level(user)
    if unseen_gold_std && expert_user
      classification.expert_classifier = expert_level
    end
  end

  def add_seen_before_for_user
    if should_update_seen? && !subjects_are_unseen_by_user?
      update_classification_metadata(:seen_before, true)
    end
  end

  def add_project_live_state
    update_classification_metadata(:live_project, project.live)
  end

  def add_user_groups
    return if classification.anonymous?
    update_classification_metadata(:user_group_ids, user.non_identity_user_group_ids)
  end

  def mark_classification_lifecycled_at
    classification.update_columns(lifecycled_at: Time.zone.now)
  end

  private

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
    @workflow ||= Workflow.find_without_json_attrs(classification.workflow_id)
  end

  def project
    @project ||= classification.project
  end

  def subject_ids
    @subject_ids ||= classification.subject_ids
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

  def create?
    action == "create"
  end

  def update?
    action == "update"
  end
end

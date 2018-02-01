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
    return if action == "create" && classification.lifecycled_at.present?

    Classification.transaction(requires_new: true) do
      update_classification_data
      # TODO: do we need these actions in the same transaction?
      # try to keep transactions short when we can
      process_project_preference
      create_recent
      update_seen_subjects
    end

    create_export_row
    notify_subject_selector
    update_counters
    publish_data
  end

  def update_classification_data
    if classification.complete?
      mark_expert_classifier
      add_seen_before_for_user
      add_project_live_state
      add_user_groups
      add_lifecycled_at
      classification.save!
    end
  end

  def update_counters
    return unless should_count_towards_retirement?

    classification.subject_ids.each do |sid|
      ClassificationCountWorker.perform_async(sid, classification.workflow.id, update?)
    end
  end

  def process_project_preference
    unless classification.anonymous?
      UserProjectPreferences::FindOrCreate.run! user: user, project: project
    end
  end

  def create_recent
    return unless completed_user_classification?
    return if subjects_are_seen_by_user?

    Recent.create_from_classification(classification)
  end

  def update_seen_subjects
    return unless completed_user_classification?
    return if subjects_are_seen_by_user?

    UserSeenSubject.add_seen_subjects_for_user(**user_workflow_subject)
  end

  def publish_data
    return unless classification.complete?

    PublishClassificationWorker.perform_async(classification.id)
  end

  def notify_subject_selector
    return unless completed_user_classification?
    return if subjects_are_seen_by_user?

    subject_ids.each do |subject_id|
      NotifySubjectSelectorOfSeenWorker.perform_async(workflow.id, user.try(:id), subject_id)
    end
  end

  def create_export_row
    return unless classification.complete?
    if Panoptes.flipper[:create_classification_export_row_in_lifecycle].enabled?
      ClassificationExportRowWorker.perform_async(classification.id)
    end
  end

  def mark_expert_classifier
    unseen_gold_std = !subjects_are_seen_by_user? && classification.gold_standard
    expert_user = user && expert_level = project.expert_classifier_level(user)
    if unseen_gold_std && expert_user
      classification.expert_classifier = expert_level
    end
  end

  def add_seen_before_for_user
    if completed_user_classification? && subjects_are_seen_by_user?
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

  def add_lifecycled_at
    classification.lifecycled_at = Time.zone.now
  end

  private

  def subjects_are_seen_by_user?
    return @subjects_are_seen_by_user if defined?(@subjects_are_seen_by_user)
    @subjects_are_seen_by_user = if user
      UserSeenSubject.has_seen_subjects_for_workflow?(
        user,
        workflow,
        subject_ids
      )
    else
      false
    end
  end

  def should_count_towards_retirement?
    return false unless classification.complete?
    return false if subjects_are_seen_by_user?
    true
  end

  def completed_user_classification?
    !classification.anonymous? && classification.complete?
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

  def update?
    action == "update"
  end
end

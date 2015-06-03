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

    dequeue_subject
    update_seen_subjects
    ClassificationWorker.perform_async(classification.id, action.to_s)
  end

  def transact!(&block)
    Classification.transaction do
      mark_expert_classifier if subjects_are_unseen_by_user?
      instance_eval(&block) if block_given?
      publish_to_kafka
    end
  end

  def dequeue_subject
    SubjectQueue.dequeue(workflow,
                         SetMemberSubject
                           .by_subject_workflow(subject_ids, classification.workflow)
                           .pluck(:id),
                         user: user)
  end

  def create_project_preference
    return unless should_create_project_preference?
    UserProjectPreference.where(user: user, project: project)
      .first_or_create do |up|
        up.email_communication = user.project_email_communication
        up.preferences = {}
      end
  end

  def update_seen_subjects
    return unless should_update_seen?
    UserSeenSubject.add_seen_subjects_for_user(**user_workflow_subject)
  end

  def publish_to_kafka
    return unless classification.complete?
    classification_json = ClassificationSerializer.serialize(classification).to_json
    MultiKafkaProducer.publish('classifications', [classification.project.id, classification_json])
  end

  def mark_expert_classifier
    return unless classification.gold_standard
    if user && expert_level = project.expert_classifier_level(user)
      classification.update(expert_classifier: expert_level)
    end
  end

  def subjects_are_unseen_by_user?
    !UserSeenSubject.find_by(user: user, workflow: workflow)
      .try(:subjects_seen?, subject_ids)
  rescue ActiveRecord::RecordNotFound
    true
  end

  def should_count_towards_retirement?
    return false if classification.seen_before?
    classification.anonymous? || subjects_are_unseen_by_user?
  end

  private

  def create_recent
    return unless should_update_seen?
    Recent.create_from_classification(classification)
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
end

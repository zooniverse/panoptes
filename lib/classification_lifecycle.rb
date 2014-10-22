class ClassificationLifecycle
  attr_reader :classification, :cellect_host
  
  def initialize(classification, cellect_host=nil)
    @classification, @cellect_host = classification, cellect_host
  end

  def queue(action)
    update_cellect
    ClassificationWorker.perform_async(classification.id, action)
  end

  def transact!(&block)
    Classification.transaction do
      update_seen_subjects
      dequeue_subject
      instance_eval &block if block_given?
      publish_to_kafka
    end
  end

  def update_cellect
    return unless should_update_seen?
    Cellect::Client.connection
      .add_seen(user_id: user.try(:id),
                workflow_id: workflow.id,
                subject_id: set_member_subject.id,
                host: cellect_host)
  end

  def dequeue_subject
    return unless should_dequeue_subject?
    UserSubjectQueue.dequeue_subject_for_user(**user_workflow_subject)
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
    UserSeenSubject.add_seen_subject_for_user(**user_workflow_subject)
  end

  def publish_to_kafka
    return unless classification.complete?
    classification_json = ClassificationSerializer.serialize(classification).to_json
    MultiKafkaProducer.publish('classifications', [classification.project.id, classification_json])
  end
  
  private

  def should_update_seen?
    !classification.anonymous? && classification.complete?
  end

  def should_dequeue_subject?
    !classification.anonymous? &&
      UserSubjectQueue.is_subject_queued?(**user_workflow_subject)
  end

  def should_create_project_preference?
    !classification.anonymous?
  end

  def user
    classification.user
  end

  def workflow
    classification.workflow
  end

  def project
    classification.project
  end

  def set_member_subject
    classification.set_member_subject
  end
  
  def user_workflow_subject
    {
      user: user,
      workflow: workflow,
      set_member_subject: set_member_subject
    }
  end
end

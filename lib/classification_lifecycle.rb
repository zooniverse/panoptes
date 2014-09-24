class ClassificationLifecycle
  attr_reader :classification, :cellect_host
  
  def initialize(classification, cellect_host)
    @classification, @cellect_host = classification, cellect_host
  end
  
  def on_create
    if should_update_seen?
      update_cellect
      update_seen_subjects
    end
    
    dequeue_subject if should_dequeue_subject?
    create_project_preference if should_create_project_preference?
  end

  def on_update
    if should_update_seen?
      update_cellect
      update_seen_subjects
    end
    
    dequeue_subject if should_dequeue_subject?
  end

  private
  
  def should_update_seen?
    !classification.anonymous? && classification.complete?
  end

  def should_dequeue_subject?
    !classification.anonymous? &&
      UserEnqueuedSubject.is_subject_queued?(**user_workflow_subject)
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
  
  def update_cellect
    Cellect::Client.connection
      .add_seen(user_id: user.id,
                workflow_id: workflow.id,
                subject_id: set_member_subject.id,
                host: cellect_host)
  end

  def dequeue_subject
    UserEnqueuedSubject.dequeue_subject_for_user(**user_workflow_subject)
  end

  def create_project_preference
    UserProjectPreference.where(user: user, project: project)
      .first_or_create do |up|
      up.email_communication = user.project_email_communication
      up.preferences = {}
    end
  end

  def update_seen_subjects
    UserSeenSubject.add_seen_subject_for_user(**user_workflow_subject)
  end

  def user_workflow_subject
    {
     user: user,
     workflow: workflow,
     set_member_subject_id: set_member_subject.id
    }
  end
end

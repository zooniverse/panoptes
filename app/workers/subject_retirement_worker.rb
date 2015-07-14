class SubjectRetirementWorker
  include Sidekiq::Worker

  def perform(subject_id, workflow_id)
    subject = Subject.find(subject_id)
    workflow = Workflow.find(workflow_id)

    if workflow.project.live
      SubjectLifecycle.new(subject).retire_for(workflow)
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end

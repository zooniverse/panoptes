class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(status_id)
    status = load_subject_workflow_status(status_id)
    if status&.retire?
      status.retire!("classification_count")

      workflow_id = status.workflow_id
      WorkflowRetiredCountWorker.perform_async(workflow_id)
      PublishRetirementEventWorker.perform_async(workflow_id)
      NotifySubjectSelectorOfRetirementWorker
        .perform_async(status.subject_id, workflow_id)
    end
  end

  private

  def load_subject_workflow_status(status_id)
    SubjectWorkflowStatus.where(id: status_id).eager_load(:workflow).first
  end
end

class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(status_id, reason="classification_count")
    status = SubjectWorkflowStatus.where(id: status_id).first
    if status&.retire?
      status.retire!(reason)

      workflow_id = status.workflow_id
      WorkflowRetiredCountWorker.perform_async(workflow_id)
      PublishRetirementEventWorker.perform_async(workflow_id)
      NotifySubjectSelectorOfRetirementWorker
        .perform_async(status.subject_id, workflow_id)
    end
  end
end

class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(status_id, reason="classification_count", force_retire: false)
    status = SubjectWorkflowStatus.find(status_id)
    if status.retire?
      status.retire!(reason)

      workflow_id = status.workflow_id
      WorkflowRetiredCountWorker.perform_async(workflow_id)
      PublishRetirementEventWorker.perform_async(workflow_id)
      NotifySubjectSelectorOfRetirementWorker
        .perform_async(status.subject_id, workflow_id)
    end
  rescue ActiveRecord::RecordNotFound
  end
end

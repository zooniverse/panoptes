class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(status_id, reason="classification_count", force_retire: false)
    status = SubjectWorkflowStatus.find(status_id)
    not_retired = !status.retired?
    if (force_retire && not_retired) || status.retire?
      status.retire!(reason)

      WorkflowRetiredCountWorker.perform_async(status.workflow_id)
      PublishRetirementEventWorker.perform_async(status.workflow_id)
      NotifySubjectSelectorOfRetirementWorker.perform_async(
        status.subject_id, status.workflow_id
      )
    end
  rescue ActiveRecord::RecordNotFound
  end
end

class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(status_id, force_retire=false, reason="classification_count")
    status = SubjectWorkflowStatus.find(status_id)
    not_retired = !status.retired?
    if (force_retire && not_retired) || status.retire?
      status.retire!(reason)

      WorkflowRetiredCountWorker.perform_async(status.workflow_id)
      PublishRetirementEventWorker.perform_async(status.workflow_id)
      NotifySubjectSelectorOfRetirementWorker.perform_async(
        status.subject_id, status.workflow_id
      )
      # recalculate the subject set completeness metric
      # for the workflow and each linked subject's subject_set
      status.subject.subject_set_ids.each do |subject_set_id|
        SubjectSetCompletenessWorker.perform_async(subject_set_id, status.workflow_id)
      end
    end
  rescue ActiveRecord::RecordNotFound
  end
end

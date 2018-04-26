class RetireSubjectWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(workflow_id, subject_ids, reason=nil)
    workflow = Workflow.find(workflow_id)
    Workflow.transaction do
      subject_ids.each do |subject_id|
        begin
          workflow.retire_subject(subject_id, reason)
        rescue ActiveRecord::RecordInvalid
        end
      end
    end

    RefreshWorkflowStatusWorker.perform_async(workflow.id)

    subject_ids.each do |subject_id|
      NotifySubjectSelectorOfRetirementWorker.perform_async(subject_id, workflow.id)
    end
  rescue ActiveRecord::RecordNotFound
  end
end

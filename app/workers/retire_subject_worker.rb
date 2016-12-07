class RetireSubjectWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(workflow_id, subject_ids, reason=nil)
    workflow = Workflow.find(workflow_id)
    Workflow.transaction do
      subject_ids.each do |subject_id|
        workflow.retire_subject(subject_id, reason)
      end
    end

    WorkflowRetiredCountWorker.perform_async(workflow.id)

    return unless Panoptes.use_cellect?(workflow)
    subject_ids.each do |subject_id|
      RetireCellectWorker.perform_async(subject_id, workflow.id)
    end
  rescue ActiveRecord::RecordNotFound
  end
end

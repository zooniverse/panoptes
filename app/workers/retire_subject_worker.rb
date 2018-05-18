class RetireSubjectWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(workflow_id, subject_ids, reason=nil)
    workflow = Workflow.find(workflow_id)
    retired_subjects = 0

    Workflow.transaction do
      subject_ids.each do |subject_id|
        begin
          if workflow.retire_subject(subject_id, reason)
            retired_subjects += 1
          end
        rescue ActiveRecord::RecordInvalid
        end
      end
    end

    if retired_subjects > 0
      WorkflowRetiredCountWorker.perform_async(workflow.id)

      subject_ids.each do |subject_id|
        NotifySubjectSelectorOfRetirementWorker.perform_async(subject_id, workflow.id)
      end
    end
  rescue ActiveRecord::RecordNotFound
  end
end

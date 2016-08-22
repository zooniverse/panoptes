module Workflows
  class RetireSubjects < Operation
    validates :retirement_reason, inclusion: { in: SubjectWorkflowStatus.retirement_reasons.keys, allow_nil: true }

    object :workflow

    integer :subject_id, default: nil
    array :subject_ids, default: [] do
      integer
    end
    string :retirement_reason, default: nil

    def execute
      Workflow.transaction do
        subject_ids.each do |subject_id|
          workflow.retire_subject(subject_id, retirement_reason)
        end

        WorkflowRetiredCountWorker.perform_async(workflow.id)

        # This needs to be the last step in the transaction. If the transaction
        # rolls back, we must not have enqueued these jobs yet.
        if Panoptes.use_cellect?(workflow)
          subject_ids.each do |subject_id|
            RetireCellectWorker.perform_async(subject_id, workflow.id)
          end
        end
      end
    end

    def subject_ids
      Array.wrap(@subject_ids) | Array.wrap(@subject_id)
    end
  end
end

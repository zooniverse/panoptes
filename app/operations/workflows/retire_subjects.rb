module Workflows
  class RetireSubjects < Operation
    object :workflow

    integer :subject_id, default: nil
    array :subject_ids, default: [] do
      integer
    end

    def execute
      Workflow.transaction do
        subject_ids.each do |subject_id|
          workflow.retire_subject(subject_id)
        end

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

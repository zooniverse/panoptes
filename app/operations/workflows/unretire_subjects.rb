module Workflows
    class UnretireSubjects < Operation
        validates :workflow_id, presence: true

        integer :workflow_id
        integer :subject_id, default: nil
        array :subject_ids, default: [] do
            integer
        end

        def execute
            return if subject_ids.empty?

            SubjectWorkflowStatus.where.not(retired_at: nil).where(workflow_id: workflow_id, subject_id: subject_ids).update_all(retired_at: nil, retirement_reason: nil)
            RefreshWorkflowStatusWorker.perform_async(workflow_id)
            NotifySubjectSelectorOfChangeWorker.perform_async(workflow_id)
        end

        def subject_ids 
            @cached_subject_ids ||= Array.wrap(@subject_ids) | Array.wrap(@subject_id)
        end

    end
end
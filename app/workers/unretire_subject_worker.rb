class UnretireSubjectWorker
    include Sidekiq::Worker
    attr_reader :workflow_id

    sidekiq_options queue: :high
    
    def perform(workflow_id, subject_ids)
        @workflow_id = workflow_id

        if workflow_exists?
            SubjectWorkflowStatus.where.not(retired_at: nil).where(workflow_id: workflow_id, subject_id: subject_ids).update_all(retired_at: nil, retirement_reason: nil)
            RefreshWorkflowStatusWorker.perform_async(workflow_id)
            NotifySubjectSelectorOfChangeWorker.perform_async(workflow_id)
        end
    end

    private

    def workflow_exists?
        Workflow.where(id: workflow_id).exists?
    end
end
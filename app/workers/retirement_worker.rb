class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(count_id)
    count = SubjectWorkflowCount.find(count_id)
    if count.retire?
      count.retire! do
        deactivate_workflow!(count.workflow)
      end
    end
  end

  def deactivate_workflow!(workflow)
    if workflow.finished?
      Workflow.where(id: workflow.id).update_all(active: false)
    end
  end
end

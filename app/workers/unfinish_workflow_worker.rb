class UnfinishWorkflowWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  sidekiq_options congestion: {
    interval: 30,
    max_in_interval: 1,
    min_delay: 0,
    reject_with: :cancel,
    key: ->(project_id) {
      "unfinish_workflow_#{workflow_id}_worker"
    }
  }

  def perform(workflow_id)
    workflow = Workflow.find(workflow_id)
    if workflow.finished_at && workflow.finished_active_data?
      Workflow.where(id: workflow.id).update_all(finished_at: nil)
    end
  end
end

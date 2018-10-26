class UnfinishWorkflowWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  sidekiq_options congestion: {
    interval: 30,
    max_in_interval: 1,
    min_delay: 0,
    reject_with: :cancel,
    key: ->(workflow_id) {
      "unfinish_workflow_#{workflow_id}_worker"
    }
  }

  def perform(workflow_id)
    workflow = Workflow.find_without_json_attrs(workflow_id)
    workflow.update_attribute(:finished_at, nil) if workflow.finished_at
  end
end

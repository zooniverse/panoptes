class RefreshWorkflowStatusWorker
  include Sidekiq::Worker

  sidekiq_options congestion: {
    interval: 15,
    max_in_interval: 1,
    min_delay: 15,
    reject_with: :reschedule,
    key: ->(workflow_id) {
      "refresh_worklow_status_worker_#{workflow_id}"
    }
  }

  sidekiq_options queue: :data_high, unique: :until_executing

  def perform(workflow_id)
    workflow = Workflow.find(workflow_id)
    # run the first worker manually to ensure we don't have state race
    # conditions between workers and/or db transactions
    UnfinishWorkflowWorker.new.perform(workflow.id)
    WorkflowRetiredCountWorker.perform_async(workflow.id)
  end
end

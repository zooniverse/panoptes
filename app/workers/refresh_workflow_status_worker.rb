class RefreshWorkflowStatusWorker
  include Sidekiq::Worker

  # drop any other jobs once this is in the queue
  # and until it has finished executing
  sidekiq_options queue: :data_high, unique: :until_executed

  def perform(workflow_id)
    workflow = Workflow.find(workflow_id)
    # run these in band and in order to ensure
    # we don't have state race conditions
    # between workers and/or db transactions
    ordered_workers[0..1].each do |worker|
      worker.perform(workflow.id)
    end
    ordered_workers.last.perform(workflow.project_id)
  end

  def ordered_workers
    [
      UnfinishWorkflowWorker,
      WorkflowRetiredCountWorker,
      CalculateProjectCompletenessWorker
    ].map(&:new)
  end
end

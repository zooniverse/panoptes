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
    UnfinishWorkflowWorker.new.perform(workflow.id)
    WorkflowRetiredCountWorker.new.perform(workflow.id)
    CalculateProjectCompletenessWorker.new.perform(workflow.project_id)
  end
end

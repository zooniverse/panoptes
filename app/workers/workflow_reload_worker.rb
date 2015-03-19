class WorkflowReloadWorker
  include Sidekiq::Worker

  def perform(workflow_id)
    CellectClient.reload_workflow(workflow_id)
  end
end

require 'subjects/cellect_client'

class ReloadCellectWorker
  include Sidekiq::Worker

  def perform(workflow_id)
    workflow = Workflow.find(workflow_id)
    if Panoptes.use_cellect?(workflow)
      Subjects::CellectClient.reload_workflow(workflow_id)
    end
  rescue Subjects::CellectClient::ConnectionError, ActiveRecord::RecordNotFound
  end
end

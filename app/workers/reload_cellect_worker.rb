require 'subjects/cellect_client'

class ReloadCellectWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3, queue: :data_high

  def perform(workflow_id)
    workflow = Workflow.find(workflow_id)
    if Panoptes.use_cellect?(workflow)
      Subjects::CellectClient.reload_workflow(workflow_id)
    end
  rescue ActiveRecord::RecordNotFound
  end
end

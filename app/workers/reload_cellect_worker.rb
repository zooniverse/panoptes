class ReloadCellectWorker
  include Sidekiq::Worker

  def perform(workflow_id)
    return unless Panoptes.cellect_on
    Subjects::CellectClient.reload_workflow(workflow_id)
  rescue Subjects::CellectClient::ConnectionError
  end
end

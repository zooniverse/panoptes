require 'subjects/cellect_client'

class SeenCellectWorker
  include Sidekiq::Worker

  # SGL-PRIORITY
  # sidekiq_options retry: 3, queue: :data_high
  sidekiq_options retry: 3, queue: :high, dead: false

  def perform(workflow_id, user_id, subject_id)
    return if user_id.nil?
    workflow = Workflow.find(workflow_id)
    if Panoptes.use_cellect?(workflow)
      Subjects::CellectClient.add_seen(workflow.id, user_id, subject_id)
    end
  rescue ActiveRecord::RecordNotFound
  end
end

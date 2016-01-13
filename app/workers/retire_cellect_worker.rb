require 'subjects/cellect_client'

class RetireCellectWorker
  include Sidekiq::Worker

  # SGL-PRIORITY
  # sidekiq_options retry: 3, queue: :data_high
  sidekiq_options retry: 3, queue: :high

  def perform(subject_id, workflow_id)
    workflow = Workflow.find(workflow_id)
    if Panoptes.use_cellect?(workflow)
      smses = workflow.set_member_subjects.where(subject_id: subject_id)
      smses.each do |sms|
        params = [ subject_id, workflow_id, sms.subject_set_id ]
        Subjects::CellectClient.remove_subject(*params)
      end
    end
  rescue ActiveRecord::RecordNotFound
  end
end

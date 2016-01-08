class RetireCellectWorker
  include Sidekiq::Worker

  def perform(subject_id, workflow_id)
    workflow = Workflow.find(workflow_id)
    if Panoptes.use_cellect?(workflow)
      smses = workflow.set_member_subjects.where(subject_id: subject_id)
      smses.each do |sms|
          Subjects::CellectClient
          .remove_subject(subject_id, workflow_id, sms.subject_set_id)
      end
    end
  rescue Subjects::CellectClient::ConnectionError, ActiveRecord::RecordNotFound
  end
end

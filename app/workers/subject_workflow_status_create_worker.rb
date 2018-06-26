class SubjectWorkflowStatusCreateWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high, unique: :until_executed

  def perform(subject_id, workflow_id)
    if SetMemberSubject.by_subject_workflow(subject_id, workflow_id).exists?
      SubjectWorkflowStatus.create!(
        subject_id: subject_id,
        workflow_id: workflow_id
      )
    end
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
  end
end

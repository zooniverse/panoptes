  class SubjectWorkflowStatusCreateWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high, lock: :until_executed

  def perform(subject_id, workflow_id)
    return unless Panoptes.flipper[:subject_workflow_status_create_worker].enabled?

    if SetMemberSubject.by_subject_workflow(subject_id, workflow_id).exists?
      SubjectWorkflowStatus.create!(
        subject_id: subject_id,
        workflow_id: workflow_id
      )
    end
  rescue ActiveRecord::RecordInvalid
  end
end

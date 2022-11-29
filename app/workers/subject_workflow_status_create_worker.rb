class SubjectWorkflowStatusCreateWorker
  include Sidekiq::Worker

  def perform(subject_id, workflow_id)
    return unless Flipper.enabled?(:subject_workflow_status_create_worker)

    if SetMemberSubject.by_subject_workflow(subject_id, workflow_id).exists?
      SubjectWorkflowStatus.create!(
        subject_id: subject_id,
        workflow_id: workflow_id
      )
    end
  rescue ActiveRecord::RecordInvalid
  end
end

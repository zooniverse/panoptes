class SubjectSetStatusesCreateWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_medium, lock: :until_executed

  def perform(subject_set_id, workflow_id)
    return unless Panoptes.flipper[:subject_set_statuses_create_worker].enabled?

    set_is_linked_to_workflow = SubjectSetsWorkflow.where(
      subject_set_id: subject_set_id,
      workflow_id: workflow_id
    ).exists?
    return unless set_is_linked_to_workflow

    linked_subject_select_scope = SetMemberSubject
      .where(subject_set_id: subject_set_id)
      .select(:id,:subject_id)

    linked_subject_select_scope.find_each do |sms|
      SubjectWorkflowStatusCreateWorker.perform_async(
        sms.subject_id,
        workflow_id
      )
    end
  end
end

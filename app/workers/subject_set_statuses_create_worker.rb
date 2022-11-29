class SubjectSetStatusesCreateWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low, lock: :until_executed

  def perform(subject_set_id, workflow_id)
    return unless Flipper.enabled?(:subject_set_statuses_create_worker)

    set_is_linked_to_workflow = SubjectSetsWorkflow.where(
      subject_set_id: subject_set_id,
      workflow_id: workflow_id
    ).exists?
    return unless set_is_linked_to_workflow

    linked_subject_select_scope = SetMemberSubject
      .where(subject_set_id: subject_set_id)
      .select(:id,:subject_id)

    duration = linked_subject_select_scope.count(:id) * 4
    linked_subject_select_scope.find_each do |sms|
      SubjectWorkflowStatusCreateWorker.perform_in(
        duration.seconds*rand,
        sms.subject_id,
        workflow_id
      )
    end
  end
end

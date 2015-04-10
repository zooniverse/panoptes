class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(sms_id, workflow_id)
    sms = SetMemberSubject.find(sms_id)
    if sms.retire?
      ActiveRecord::Base.transaction(requires_new: true) do
        SetMemberSubject.update(sms.id, state: SetMemberSubject.states[:retired])
        SubjectSet.increment_counter(:retired_set_member_subjects_count, sms.subject_set.id)
        SubjectQueue.dequeue_for_all(Workflow.find(workflow_id), sms)
      end
    end
  end
end

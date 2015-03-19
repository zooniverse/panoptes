class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high, retry: 3
  
  def perform(sms_id, workflow_id)
    sms = SetMemberSubject.find(sms_id)
    if sms.retire?
      ActiveRecord::Base.transaction(requires_new: true) do
        SetMemberSubject.update(sms.id, state: SetMemberSubject.states[:retired])
        SubjectSet.increment_counter(:retired_set_member_subjects_count, sms.subject_set.id)
      end

      sms.reload

      if sms.retired?
        CellectClient.remove_subject(sms.subject_id,
                                     workflow_id,
                                     sms.subject_set_id)
      end
    end
  end
end

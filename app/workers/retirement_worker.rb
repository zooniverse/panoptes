class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high, retry: 3
  
  def perform(sms_id, workflow_id)
    sms = SetMemberSubject.find(sms_id)
    if sms.retire?
      sms.retired!
      Cellect::Client.connection
        .remove_subject(sms.subject_id,
                        workflow_id: workflow_id,
                        group_id: sms.subject_set_id)
    end
  end
end

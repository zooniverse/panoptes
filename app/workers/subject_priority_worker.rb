class SubjectPriorityWorker
  include Sidekiq::Worker

  def perform(sms_ids)
    sms_ids.each do |sms_id|
      sms = SetMemberSubject.find(sms_id)
      subject = Subject.find(sms.subject_id)
      if subject.metadata.key?("#priority")
        sms.update_column(:priority, subject.metadata["#priority"].to_i)
      end
    end
  end
end

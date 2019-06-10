class SubjectMetadataWorker
  include Sidekiq::Worker

  def perform(set_id)

    smses = SetMemberSubject.where(subject_set_id: set_id)

    smses.each do |sms|
      subject = Subject.find(sms.subject_id)

      if subject.metadata.key?("#priority")
        sms.update_column(:priority, subject.metadata["#priority"].to_i)
      end

      if subject.metadata.key?("#training_subject")
        # Requires migration
        # sms.update_column(:training_subject, subject.metadata["#training_subject"])
      end
    end
  end
end

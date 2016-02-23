module Subjects
  class SeenRemover

    attr_reader :user_seen_subject, :sms_ids

    def initialize(user_seens, append_sms_ids)
      @user_seen_subject = user_seens
      @sms_ids = append_sms_ids
    end

    def unseen_ids
      sms_ids - seen_before_sms_ids
    end

    private

    def seen_before_sms_ids
      seen_before = if user_seen_subject
        SetMemberSubject.where(
          id: sms_ids,
          subject_id: user_seen_subject.subject_ids
        )
      else
        SetMemberSubject.none
      end
      seen_before.pluck(:id)
    end
  end
end

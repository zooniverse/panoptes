module Subjects
  class SeenRemover

    attr_reader :user, :workflow, :append_sms_ids

    def initialize(user, workflow, append_ids)
      @user = user
      @workflow = workflow
      @append_sms_ids = append_ids
    end

    def unseen_ids
      append_sms_ids - seen_before_sms_ids
    end

    private

    def seen_before_sms_ids
      seen_before = if user_seen_subject
        SetMemberSubject.where(
          id: append_sms_ids,
          subject_id: user_seen_subject.subject_ids
        )
      else
        SetMemberSubject.none
      end
      seen_before.pluck(:id)
    end

    def user_seen_subject
      @user_seen_subject ||= if user
        UserSeenSubject.find_by(user: user, workflow: workflow)
      end
    end
  end
end

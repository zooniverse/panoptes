module Subjects
  class CompleteRemover

    attr_reader :user, :workflow, :sms_ids

    def initialize(user, workflow, sms_ids)
      @user = user
      @workflow = workflow
      @sms_ids = sms_ids
    end

    def incomplete_ids
      return sms_ids if sms_ids.empty?
      sms_ids - retired_seen_ids
    end

    private

    def retired_seen_ids
      Set.new(retired_seen_scope.pluck(:id)).to_a
    end

    def retired_seen_scope
      if user_seen_ids.empty?
        retired_scope
      else
        retired_scope.union_all(seen_scope)
      end
    end

    def retired_scope
      SetMemberSubject.retired_for_workflow(workflow).where(set_member_subjects: {id: sms_ids})
    end

    def seen_scope
      SetMemberSubject.where(id: sms_ids, subject_id: user_seen_ids)
    end

    def user_seens
      @user_seens ||= UserSeenSubject.find_by(user: user, workflow: workflow)
    end

    def user_seen_ids
      @user_seen_ids ||= if user_seens
        user_seens.subject_ids
      else
        []
      end
    end
  end
end

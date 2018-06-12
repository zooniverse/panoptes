module Subjects
  class CompleteRemover

    attr_reader :user, :workflow, :subject_ids

    def initialize(user, workflow, subject_ids)
      @user = user
      @workflow = workflow
      @subject_ids = subject_ids
    end

    def incomplete_ids
      return subject_ids if subject_ids.empty?
      subject_ids - retired_seen_ids
    end

    private

    def retired_seen_ids
      Set.new(retired_seen_scope.pluck(:subject_id)).to_a
    end

    def retired_seen_scope
      if user_seen_ids.empty?
        retired_scope
      else
        retired_scope.union_all(seen_scope)
      end
    end

    def retired_scope
      SetMemberSubject
      .retired_for_workflow(workflow)
      .where(set_member_subjects: {subject_id: subject_ids})
    end

    def seen_scope
      SetMemberSubject.where(subject_id: user_seen_ids)
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

module Subjects
  class SetMemberSubjectSelector
    attr_reader :workflow, :user
    SELECT_FIELDS = '"set_member_subjects"."id"'.freeze

    def initialize(workflow, user)
      @workflow = workflow
      @user = user
    end

    def set_member_subjects
      selected = if user
        select_non_retired_unseen_for_user
      else
        select_non_retired
      end
      selected.select(SELECT_FIELDS)
    end

    private

    def select_non_retired
      SetMemberSubject.non_retired_for_workflow(workflow)
    end

    def select_unseen_for_user
      SetMemberSubject.unseen_for_user_by_workflow(user, workflow)
    end

    def select_non_retired_unseen_for_user
      select_unseen_for_user.merge(select_non_retired)
    end
  end
end

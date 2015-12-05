module Subjects
  class SetMemberSubjectSelector
    attr_reader :workflow, :user
    SELECT_FIELDS = '"set_member_subjects"."id",' +
    '"set_member_subjects"."random",' +
    '"set_member_subjects"."priority"'

    def initialize(workflow, user)
      @workflow = workflow
      @user = user
    end

    def set_member_subjects
      selection = if !user && !workflow.finished?
                    select_non_retired
                  elsif select_from_all?
                    select_all_workflow_set_member_subjects
                  else
                    select_non_retired_unseen_for_user
                  end
      if all_user_unseen_data_is_retired?(selection)
        selection = select_unseen_for_user
      end
      selection.select(SELECT_FIELDS)
    end

    def select_from_all?
      !user ||
      user_has_not_seen_workflow_subjects? ||
      workflow.finished? ||
      user.has_finished?(workflow)
    end

    private

    def all_user_unseen_data_is_retired?(selection)
      user && !selection.exists?
    end

    def user_has_not_seen_workflow_subjects?
      !user.user_seen_subjects.where(workflow: workflow).exists?
    end

    def select_non_retired
      SetMemberSubject.non_retired_for_workflow(workflow)
    end

    def select_all_workflow_set_member_subjects
      workflow.set_member_subjects
    end

    def select_unseen_for_user
      SetMemberSubject.unseen_for_user_by_workflow(user, workflow)
    end

    def select_non_retired_unseen_for_user
      select_unseen_for_user.merge(select_non_retired)
    end
  end
end

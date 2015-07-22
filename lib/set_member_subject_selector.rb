class SetMemberSubjectSelector
  attr_reader :workflow, :user
  SELECT_FIELDS = '"set_member_subjects"."id", "set_member_subjects"."random"'

  def initialize(workflow, user)
    @workflow = workflow
    @user = user
  end

  def set_member_subjects
    to_classify = select_set_member_subjects_to_classify
    if to_classify.empty?
      select_all_workflow_set_member_subjects
    else
      to_classify
    end
  end

  def select_from_all?
    !user ||
    user_has_not_seen_workflow_subjects? ||
    workflow.finished? ||
    user.has_finished?(workflow)
  end

  private

  def user_has_not_seen_workflow_subjects?
    !user.user_seen_subjects.where(workflow: workflow).exists?
  end

  def select_set_member_subjects_to_classify
    if select_from_all?
      select_all_workflow_set_member_subjects
    else
      select_non_retired_unseen_for_user
    end
  end

  def select_all_workflow_set_member_subjects
    workflow.set_member_subjects.select(SELECT_FIELDS)
  end

  def select_non_retired_unseen_for_user
    SetMemberSubject.unseen_for_user_by_workflow(user, workflow)
      .merge(SetMemberSubject.non_retired_for_workflow(workflow))
      .select(SELECT_FIELDS)
  end
end

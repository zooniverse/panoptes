class SetMemberSubjectSelector
  attr_reader :workflow, :user
  SELECT_FIELDS = '"set_member_subjects"."id", "set_member_subjects"."random"'

  def initialize(workflow, user)
    @workflow = workflow
    @user = user
  end

  def set_member_subjects
    if select_from_all?
      workflow.set_member_subjects.select(SELECT_FIELDS)
    else
      SetMemberSubject.select(SELECT_FIELDS)
        .joins(subject_set: {workflows: :user_seen_subjects})
        .where(user_seen_subjects: {user_id: user.id},
               workflows: {id: workflow.id})
        .where.not('? = ANY("set_member_subjects"."retired_workflow_ids")', workflow.id)
        .where.not('"set_member_subjects"."subject_id" = ANY("user_seen_subjects"."subject_ids")')
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
end

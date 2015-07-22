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
    SetMemberSubject.select(SELECT_FIELDS)
      .joins(subject_set: {workflows: :user_seen_subjects})
      .joins("LEFT OUTER JOIN subject_workflow_counts ON subject_workflow_counts.set_member_subject_id = set_member_subjects.id")
      .where(user_seen_subjects: {user_id: user.id},
             workflows: {id: workflow.id},
             subject_workflow_counts: {workflow_id: workflow.id, retired_at: nil})
      .where.not('"set_member_subjects"."subject_id" = ANY("user_seen_subjects"."subject_ids")')
    end
end

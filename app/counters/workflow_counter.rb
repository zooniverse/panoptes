class WorkflowCounter
  attr_reader :workflow

  def initialize(workflow)
    @workflow = workflow
  end

  def classifications
    sws_query.sum(:classifications_count)
  end

  def retired_subjects
    sws_query.where.not(retired_at: nil).count
  end

  def sws_query
    SubjectWorkflowStatus
    .where(workflow_id: workflow.id)
    .joins("INNER JOIN set_member_subjects ON set_member_subjects.subject_id = subject_workflow_counts.subject_id")
    .where(set_member_subjects: { subject_set_id: subject_set_ids })
  end

  private

  def subject_set_ids
    workflow.subject_sets.pluck(:id)
  end
end

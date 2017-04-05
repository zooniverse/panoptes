class WorkflowCounter

  attr_reader :workflow

  def initialize(workflow)
    @workflow = workflow
  end

  def classifications
    linked_subject_workflow_status.sum(:classifications_count)
  end

  def retired_subjects
    retired = linked_subject_workflow_status.retired
    if launch_date
      retired = retired.where("subject_workflow_counts.retired_at >= ?", launch_date)
    end
    retired.count
  end

  private

  def launch_date
    workflow.project.launch_date
  end

  def linked_subject_workflow_status
    SubjectWorkflowStatus
      .by_set(workflow.subject_sets.pluck(:id))
      .where(workflow_id: workflow.id)
  end
end

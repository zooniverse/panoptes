class WorkflowCounter

  attr_reader :workflow

  def initialize(workflow)
    @workflow = workflow
  end

  def classifications
    SubjectWorkflowStatus.where(workflow: workflow).sum(:classifications_count)
  end

  def retired_subjects
    retired = SubjectWorkflowStatus.by_set(workflow.subject_sets.pluck(:id)).retired.where(workflow_id: workflow.id)
    if launch_date
      retired = retired.where("subject_workflow_counts.retired_at >= ?", launch_date)
    end
    retired.count
  end

  private

  def launch_date
    workflow.project.launch_date
  end
end

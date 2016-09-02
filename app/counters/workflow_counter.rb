class WorkflowCounter

  attr_reader :workflow

  def initialize(workflow)
    @workflow = workflow
  end

  def classifications
    SubjectWorkflowStatus.where(workflow: workflow).sum(:classifications_count)
  end
end

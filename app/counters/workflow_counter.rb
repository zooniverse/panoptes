class WorkflowCounter

  attr_reader :workflow

  def initialize(workflow)
    @workflow = workflow
  end

  def classifications
    scope = workflow.classifications
    if launch_date = workflow.project.launch_date
      scope = workflow.classifications.where("created_at >= ?", launch_date)
    end
    scope.count
  end
end

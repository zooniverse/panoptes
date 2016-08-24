class SubjectWorkflowCounter

  attr_reader :swc

  def initialize(swc)
    @swc = swc
  end

  def classifications
    scope = SubjectWorkflowCount
      .where(id: swc.id)
      .joins("INNER JOIN classification_subjects cs ON cs.subject_id = subject_workflow_counts.subject_id")
      .joins("INNER JOIN classifications ON classifications.id = cs.classification_id")
      .joins("INNER JOIN workflows ON workflows.id = subject_workflow_counts.workflow_id")
    if launch_date = swc.workflow.project.launch_date
      scope = scope.where("classifications.created_at >= ?", launch_date)
    end
    scope.count
  end
end

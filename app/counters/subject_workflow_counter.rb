class SubjectWorkflowCounter

  attr_reader :swc

  def initialize(swc)
    @swc = swc
  end

  def classifications
    scope = Classification
      .where(workflow: swc.workflow_id)
      .joins("INNER JOIN classification_subjects cs ON cs.classification_id = classifications.id")
      .where("cs.subject_id = ?", swc.subject_id)
      .complete
    if launch_date = swc.project.launch_date
      scope = scope.where("classifications.created_at >= ?", launch_date)
    end
    scope.count
  end
end

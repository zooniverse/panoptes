class SubjectWorkflowRetirements
  def initialize(workflow, subject_ids)
    @workflow = workflow
    @subject_ids = subject_ids
  end

  def find_retirees
    SubjectWorkflowStatus.retired.by_workflow(@workflow.id).where(subject_id: @subject_ids).pluck("subject_id")
  end
end

class SubjectWorkflowRetirements
  def self.find(workflow_id, subject_ids)
    SubjectWorkflowStatus
    .retired
    .by_workflow(workflow_id)
    .by_subject(subject_ids)
    .pluck("subject_id")
  end
end

# frozen_string_literal: true

class SubjectSetWorkflowCounter
  attr_reader :subject_set_id, :workflow_id

  def initialize(subject_set_id, workflow_id)
    @subject_set_id = subject_set_id
    @workflow_id = workflow_id
  end

  # count the number of subjects in this subject set
  # that have been retired for this workflow
  def retired_subjects
    scope =
      SubjectWorkflowStatus
      .where(workflow: workflow_id)
      .joins(workflow: :subject_sets)
      .where(subject_sets: { id: subject_set_id })
      .retired

    scope.count
  end
end

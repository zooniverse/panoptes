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
    sms_subject_ids_scope = SetMemberSubject.where(subject_set_id: subject_set_id).select(:subject_id)
    scope = SubjectWorkflowStatus.where(workflow: workflow_id).where(subject_id: sms_subject_ids_scope).retired

    scope.count
  end
end

class SubjectLifecycle
  attr_reader :subject

  def initialize(subject)
    @subject = subject
  end

  def retire_for(workflow)
    ActiveRecord::Base.transaction(requires_new: true) do
      set_member_subjects = SetMemberSubject.by_subject_workflow(subject.id, workflow.id)
      retired_sms_count = set_member_subjects.update_all(["retired_workflow_ids = array_append(retired_workflow_ids, ?)", workflow.id])
      Workflow.update_counters(workflow.id, retired_set_member_subjects_count: retired_sms_count)
      SubjectQueue.dequeue_for_all(workflow, set_member_subjects.pluck(:id))
    end
  end
end

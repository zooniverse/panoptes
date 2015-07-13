class SubjectRetirementWorker
  include Sidekiq::Worker

  def perform(subject_id, workflow_id)
    workflow = Workflow.find(workflow_id)

    if workflow.project.live
      set_member_subjects = SetMemberSubject.by_subject_workflow(subject_id, workflow.id)
      retired_sms_count = set_member_subjects.update_all(["retired_workflow_ids = array_append(retired_workflow_ids, ?)", workflow.id])
      Workflow.update_counters(workflow.id, retired_set_member_subjects_count: retired_sms_count)
      SubjectQueue.dequeue_for_all(workflow, set_member_subjects.pluck(:id))
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end
end

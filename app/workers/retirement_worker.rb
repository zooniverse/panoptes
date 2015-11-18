class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(count_id)
    count = SubjectWorkflowCount.find(count_id)
    if count.retire?
      count.retire! do
        SubjectQueue.dequeue_for_all(count.workflow, count.set_member_subject_ids)
        deactivate_workflow!(count.workflow)
        publish_to_event_stream(count.workflow)
      end
    end
  end

  def deactivate_workflow!(workflow)
    if workflow.finished?
      Workflow.where(id: workflow.id).update_all(active: false)
    end
  end

  def publish_to_event_stream(workflow)
    EventStream.push('workflow_counters', Time.now,
      project_id: workflow.project_id,
      workflow_id: workflow.id,
      subjects_count: workflow.subjects_count,
      retired_subjects_count: workflow.retired_subjects_count,
      classifications_count: workflow.classifications_count)
  end
end

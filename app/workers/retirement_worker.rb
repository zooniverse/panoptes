require 'subjects/cellect_client'

class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(count_id)
    count = SubjectWorkflowCount.find(count_id)
    if count.retire?
      count.retire! do
        SubjectQueue.dequeue_for_all(count.workflow, count.set_member_subject_ids)
        finish_workflow!(count.workflow)
        notify_cellect(count)
        push_counters_to_event_stream(count.workflow)
      end
    end
  end

  def finish_workflow!(workflow, clock = Time)
    if workflow.finished?
      Workflow.where(id: workflow.id).update_all(finished_at: clock.now)
    end
  end

  def push_counters_to_event_stream(workflow)
    EventStream.push('workflow_counters',
      project_id: workflow.project_id,
      workflow_id: workflow.id,
      subjects_count: workflow.subjects_count,
      retired_subjects_count: workflow.retired_subjects_count,
      classifications_count: workflow.classifications_count)
  end

  def notify_cellect(count)
    if Panoptes.use_cellect?(count.workflow)
      count.set_member_subjects.each do |sms|
        cellect_params = [ sms.subject_id, count.workflow.id, sms.subject_set_id ]
        Subjects::CellectClient.remove_subject(*cellect_params)
      end
    end
  rescue Subjects::CellectClient::ConnectionError
  end
end

class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(count_id)
    count = SubjectWorkflowCount.find(count_id)
    if count.retire?
      count.retire! do
        SubjectQueue.dequeue_for_all(count.workflow, count.set_member_subject_ids)
        finish_workflow!(count.workflow)
      end
    end
    PublishRetirementEventWorker.perform_async(count.workflow.id)
    notify_cellect(count)
  end

  def finish_workflow!(workflow, clock = Time)
    if workflow.finished?
      Workflow.where(id: workflow.id).update_all(finished_at: clock.now)
    end
  end

  def notify_cellect(count)
    if Panoptes.use_cellect?(count.workflow)
      RetireCellectWorker.perform_async(count.subject_id, count.workflow.id)
    end
  end
end

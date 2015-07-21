class RetirementWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(count_id)
    count = SubjectWorkflowCount.find(count_id)
    if count.retire?
      count.retire! do
        SubjectQueue.dequeue_for_all(count.workflow, count.set_member_subject.id)
        deactivate_workflow!(count.workflow)
      end
    end
  end

  def deactivate_workflow!(workflow)
    if workflow.finished?
      workflow.active = false
      workflow.save!
    end
  end
end

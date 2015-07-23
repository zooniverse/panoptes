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
      ignore_optimistic_lock { workflow.update_attribute(:active, false) }
    end
  end

  private

  def ignore_optimistic_lock
    ActiveRecord::Base.lock_optimistically = false
    yield
    ActiveRecord::Base.lock_optimistically = true
  end
end

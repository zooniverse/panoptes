class QueueRemovalWorker
  include Sidekiq::Worker

  def perform(sms_ids, workflow_ids)
    SubjectQueue.dequeue_for_all(workflow_ids, sms_ids)
    SubjectQueue.where(workflow: workflow_ids).below_minimum.find_each do |queue|
      SubjectQueueWorker.perform_async(queue.workflow_id, queue.user_id)
    end
  end
end

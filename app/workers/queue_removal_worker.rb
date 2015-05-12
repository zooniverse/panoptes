class QueueRemovalWorker
  include Sidekiq::Worker

  def perform(sms_ids, workflow_ids)
    SubjectQueue.dequeue_for_all(workflow_ids, sms_ids)
  end
end

class DequeueSubjectQueueWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(queue_id, sms_ids)
    return if sms_ids.blank?
    queue = SubjectQueue.find(queue_id)
    queue.dequeue_update(sms_ids)
  rescue ActiveRecord::RecordNotFound
    nil
  end
end

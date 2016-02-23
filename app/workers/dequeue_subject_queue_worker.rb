class DequeueSubjectQueueWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_medium
  sidekiq_options congestion: {
      interval: 30,
      max_in_interval: 1,
      min_delay: 0,
      reject_with: :cancel
    }.merge({key: -> (queue_id, sms_ids) { "queue_#{ queue_id }_dequeue" }})

  def perform(queue_id, sms_ids)
    return if sms_ids.blank?
    queue = SubjectQueue.find(queue_id)
    queue.dequeue_update(sms_ids)
  rescue ActiveRecord::RecordNotFound
    nil
  end
end

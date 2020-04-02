class RandomOrderShuffleWorker
  include Sidekiq::Worker

  sidekiq_options(
    queue: :data_medium,
    congestion:
      {
        interval: ENV.fetch('SELECTION_RANDOM_INTERVAL', 60),
        max_in_interval: ENV.fetch('SELECTION_RANDOM_MAX_IN_INTERVAL', 1),
        min_delay: ENV.fetch('SELECTION_RANDOM_MIN_DELAY', 30),
        reject_with: :cancel
      }
  )

  def perform(sms_ids)
    SetMemberSubject.where(id: Array.wrap(sms_ids)).update_all("random = RANDOM()")
  end
end

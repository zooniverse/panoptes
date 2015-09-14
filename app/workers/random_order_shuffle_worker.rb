class RandomOrderShuffleWorker
  include Sidekiq::Worker

  sidekiq_options congestion: {
    interval: 1.minute,
    max_in_interval: 5,
    min_delay: 12,
    reject_with: :reschedule
  }

  def perform(sms_ids)
    SetMemberSubject.where(id: Array.wrap(sms_ids)).update_all("random = RANDOM()")
  end
end

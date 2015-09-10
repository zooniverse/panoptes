class RandomOrderShuffleWorker
  include Sidekiq::Worker

  def perform(sms_ids)
    SetMemberSubject.where(id: Array.wrap(sms_ids)).update_all("random = RANDOM()")
  end
end

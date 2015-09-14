class RandomOrderShuffleWorker
  include Sidekiq::Worker

  sidekiq_options congestion: Panoptes::SubjectSelection.random_order_shuffle_worker_opts

  def perform(sms_ids)
    SetMemberSubject.where(id: Array.wrap(sms_ids)).update_all("random = RANDOM()")
  end
end

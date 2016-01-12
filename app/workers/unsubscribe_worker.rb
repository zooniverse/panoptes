class UnsubscribeWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(email)
    if Rails.env == 'production' || Rails.env == 'test'
      JiscMailer.unsubscribe(email).deliver
    end
  end
end

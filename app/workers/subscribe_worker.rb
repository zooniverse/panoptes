class SubscribeWorker
  include Sidekiq::Worker

  def perform(email)
    if Rails.env == 'production' || Rails.env == 'test'
      JiscMailer.subscribe(email).deliver
    end
  end
end

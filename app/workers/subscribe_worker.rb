class SubscribeWorker
  include Sidekiq::Worker

  def perform(email, display_name)
    if Rails.env == 'production' || Rails.env == 'test'
      JiscMailer.subscribe(email, display_name).deliver
    end
  end
end

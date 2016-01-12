class SubscribeWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(email, name=nil)
    if Rails.env == 'production' || Rails.env == 'test'
      JiscMailer.subscribe(email).deliver
    end
  end
end

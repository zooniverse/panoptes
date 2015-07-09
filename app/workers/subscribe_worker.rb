class SubscribeWorker
  include Sidekiq::Worker

  def perform(email, name=nil)
    if Rails.env == 'production' || Rails.env == 'test'
      JiscMailer.subscribe(email).deliver
    end
  end
end

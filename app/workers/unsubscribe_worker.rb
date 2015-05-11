class UnsubscribeWorker
  include Sidekiq::Worker

  def perform(email)
    if Rails.env == 'production' || Rails.env == 'test'
      JiscMailer.unsubscribe(email).deliver
    end
  end
end

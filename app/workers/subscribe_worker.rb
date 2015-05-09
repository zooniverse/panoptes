class SubscribeWorker
  include Sidekiq::Worker

  def perform(email, display_name)
    JiscMailer.subscribe(email, display_name).deliver
  end
end

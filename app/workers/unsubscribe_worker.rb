class UnsubscribeWorker
  include Sidekiq::Worker

  def perform(email)
    JiscMailer.unsubscribe(email).deliver
  end
end

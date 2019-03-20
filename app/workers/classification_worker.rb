class ClassificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def perform(id, action)
    classification = Classification.find(id)
    ClassificationLifecycle.perform(classification, action)
  rescue ClassificationLifecycle::InvalidAction => exception
    Honeybadger.notify(exception)
  end
end

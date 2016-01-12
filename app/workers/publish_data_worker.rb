class PublishDataWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  attr_reader :classification

  def perform(classification_id)
    @classification = Classification.find(classification_id)
    if classification.complete?
      PublishClassificationWorker.perform_async(classification_id)
      PublishEventDataWorker.perform_async(classification_id)
    end
  rescue ActiveRecord::RecordNotFound
  end
end

class RecentCreateWorker
  include Sidekiq::Worker

  def perform(classification_id)
    classification = Classification.find(classification_id)
    Recent.create_from_classification(classification)
  end
end

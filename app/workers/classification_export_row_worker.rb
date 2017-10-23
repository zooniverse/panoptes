class ClassificationExportRowWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(id)
    classification = Classification.find(id)
    return unless classification.complete?
    ClassificationExportRow.create_from_classification(classification)
  rescue ActiveRecord::RecordNotUnique
  end
end

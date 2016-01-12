require "kafka_classification_serializer"
require "multi_kafka_producer"

class PublishClassificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  attr_reader :classification

  def perform(classification_id)
    @classification = Classification.find(classification_id)
    if classification.complete?
      payload = [classification.project.id, classification_json]
      MultiKafkaProducer.publish("classifications", payload)
    end
  rescue ActiveRecord::RecordNotFound
  end

  private

  def classification_json
    KafkaClassificationSerializer
    .serialize(classification, include: ['subjects']).to_json
  end
end

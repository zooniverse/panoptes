require "kafka_classification_serializer"

class PublishClassificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  attr_reader :classification

  def perform(classification_id)
    @classification = Classification.find(classification_id)
    if classification.complete?
      publish_to_kinesis!
    end
  rescue ActiveRecord::RecordNotFound
  end

  private

  def serialized_classification
    @serialized_classification ||= KafkaClassificationSerializer
      .serialize(classification, include: ['subjects'])
      .as_json
      .with_indifferent_access
  end

  def publish_to_kinesis!
    KinesisPublisher.publish("classification", classification.workflow_id, kinesis_data, kinesis_linked)
  end

  def kinesis_data
    serialized_classification[:classifications][0]
  end

  def kinesis_linked
    serialized_classification[:linked]
  end
end

require "kafka_classification_serializer"
require "event_stream"
require "multi_kafka_producer"

class PublishDataWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  attr_reader :classification

  def perform(classification_id)
    @classification = Classification.find(classification_id)
    if classification.complete?
      publish_to_kafka
      publish_to_event_stream
    end
  rescue ActiveRecord::RecordNotFound
  end

  private

  def publish_topic
    "classifications"
  end

  def publish_to_kafka
    payload = [classification.project.id, classification_json]
    MultiKafkaProducer.publish(publish_topic, payload)
  end

  def classification_json
    KafkaClassificationSerializer
    .serialize(classification, include: ['subjects']).to_json
  end

  def publish_to_event_stream
    EventStream.push(publish_topic,
      event_id: "classification-#{classification.id}",
      event_time: classification.updated_at,
      classification_id: classification.id,
      project_id: classification.project.id,
      user_id: classification_user_id,
      _ip_address: classification.user_ip.to_s
    )
  end

  def classification_user_id
    user_id = classification.user_id.to_s || classification.user_ip.to_s
    Digest::SHA1.hexdigest(user_id)
  end
end

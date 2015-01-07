module KafkaEvent
  extend ActiveSupport::Concern

  included do
    @serializers = Hash.new
  end

  module ClassMethods
    def kafka_event(kafka_key, topic: 'events', attributes: [], links: [])
      @serializers[kafka_key] = KafkaEventSerializer.new(attributes, links)
      define_singleton_method :"publish_#{ kafka_key}" do |*ids|
        delay.publish_to_kafka(topic, kafka_key, ids)
      end
    end

    def publish_to_kafka(topic, key, *ids)
      #where(id: ids).explain
      find(ids).map do |model|
        @serializers[key].serialize(model)
      end.each do |result|
        MultiKafkaProducer.publish(topic, [key.to_s, result.to_json])
      end
    end
  end
end

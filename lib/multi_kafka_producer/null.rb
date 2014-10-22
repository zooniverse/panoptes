module MultiKafkaProducer
  class Null < AbstractAdapter
    adapter_name :null

    def self.connected?
      true
    end

    def self.connect(client_id, *brokers)
      nil
    end

    def self.publish(topic, msgs_and_keys)
      msgs_and_keys.each do |msg|
        key, msg = split_msg_pair(msg)
        Rails.logger.info "Attempted to publish to #{ topic } with message #{ key } => #{ msg }"
      end
    end
  end
end

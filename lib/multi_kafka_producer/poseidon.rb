module MultiKafkaProducer
  class Poseidon < AbstractAdapter
    adapter_name :poseidon

    def self.connected?
      !!@connection
    end

    def self.connect(client_id, *brokers)
      @connection = ::Poseidon::Producer.new(brokers, client_id)
    end

    def self.publish(topic, msgs_and_keys)
      msgs = msgs_and_keys.map do |msg|
        key, msg = split_msg_pair(msg)
        ::Poseidon::MessageToSend.new(topic, msg, key)
      end
      @connection.send_messages msgs
    end

    def self.close
      @connection.close
      @connection = nil
    end
  end
end

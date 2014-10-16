module MultiKafkaProducer
  class Poseidon < AbstractAdapter
    adapter_name :poseidon

    def connected?
      !!@connection
    end

    def connect(client_id, *brokers)
      @connection = ::Poseidon::Producer.new(brokers, client_id)
    end

    def publish(topic, msgs_and_keys)
      @connection.send_messages msgs.map do |msg|
        key, msg = split_msg_pair(msg)
        ::Poseidon::MessageToSend.new(topic, msg, key)
      end
    end

    def close
      @connection.close
      @connection = nil
    end
  end
end

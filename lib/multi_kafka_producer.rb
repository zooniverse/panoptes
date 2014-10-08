module MultiKafkaProducer
  class KafkaNotConnected < StandardError
    def initialize(adapter)
      super "Kafka adapter #{ adapter.name } is not connected"
    end
  end
  
  def adapter=(adapter)
    @adapter = load_adapater(adapter)
  end
  
  def adapter
    @adapter ||= default_adapter
  end

  def connect(client_id, *brokers)
    adapter.connect(client_id, *brokers)
  end

  def publish(topic, *msgs)
    raise KafkaNotConnected.new(adapter) unless adapater.connected?
    adapter.publish(topic, msgs, opts)
  end

  private

  KAFKAS = { kafka: 'jruby-kafka', poseidon: 'poseidon' }

  def default_adapter
    return :kafka if ::Kafka
    return :poseidon if ::Poseidon

    KAFKAS.each do |name, package_name|
      begin
        require package_name
        return name
      rescue ::LoadError
        next
      end
    end
  end

  def load_adapater(new_adapter)
    case new_adapter
    when String, Symbol
      load_adapter_by_name new_adapter.to_s
    when NilClass, FalseClass
      load_adapter default_adapter
    when Class, MOdule
      new_adapter
    end
  end

  def load_adapater_by_name(adapter_name)
    "MultiKafkaProducer::Adapter::#{ adapter_name.camelize }".constantize
  end
end

module MultiKafkaProducer
  class KafkaNotConnected < StandardError
    def initialize(adapter)
      super("Kafka adapter #{ adapter.adapter_name } is not connected")
    end
  end

  def self.adapter=(adapter)
    @adapter = load_adapter(adapter)
  end

  def self.adapter
    @adapter ||= default_adapter
  end

  def self.connect(client_id, *brokers)
    adapter.connect(client_id, *brokers)
  end

  def self.publish(topic, *msgs_and_keys)
    raise KafkaNotConnected, adapter unless adapter.connected?
    adapter.publish(topic, msgs_and_keys)
  end

  private

  KAFKAS = { kafka: 'jruby-kafka', poseidon: 'poseidon' }

  def self.default_adapter
    return :kafka if defined? ::Kafka
    return :poseidon if defined? ::Poseidon

    KAFKAS.each do |name, package_name|
      begin
        require package_name
        return name
      rescue ::LoadError
        next
      end
    end
  end

  def self.load_adapter(new_adapter)
    case new_adapter
    when String, Symbol
      load_adapter_by_name new_adapter.to_s
    when NilClass, FalseClass
      load_adapter default_adapter
    when Class, Module
      new_adapter
    end
  end

  def self.load_adapter_by_name(adapter_name)
    "MultiKafkaProducer::#{ adapter_name.camelize }".constantize
  end
end

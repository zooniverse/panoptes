require 'multi_kafka_producer'

def kafka_config
  return @config if @config
  @config = YAML.load(ERB.new(File.read(Rails.root.join('config/kafka.yml'))).result)
  @config[Rails.env].symbolize_keys
rescue Errno::ENOENT
  @config = {  }
end

unless kafka_config.empty?
  MultiKafkaProducer.adapter = nil
  MultiKafkaProducer.connect(kafka_config[:producer_id],
                             *kafka_config[:brokers])
else
  MultiKafkaProducer.adapter = :null
  MultiKafkaProducer.connnect(nil, nil)
end

require 'multi_kafka_producer'

def kafka_config
  config = YAML.load(ERB.new(File.read(Rails.root.join('config/kafka.yml'))).result)
  config[Rails.env].symbolize_keys
end

MultiKafkaProducer.adapter = nil
MultiKafkaProducer.connect(kafka_config[:producer_id],
                           *kafka_config[:brokers])

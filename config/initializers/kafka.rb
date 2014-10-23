require 'multi_kafka_producer'

adapter, kafka_config = begin
                          config = YAML.load(ERB.new(File.read(Rails.root.join('config/kafka.yml'))).result)
                          config[Rails.env].symbolize_keys
                          [ nil, config ]
                        rescue Errno::ENOENT
                          [ :null, {  } ]
                        end

MultiKafkaProducer.adapter = adapter
MultiKafkaProducer.connect(kafka_config[:producer_id],
                           *kafka_config[:brokers])

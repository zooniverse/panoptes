module MultiKafkaProducer
  class AbstractAdapter
    def self.adapter_name(name=nil)
      @name = name if name
      @name
    end

    def name
      self.class.adapter_name
    end
  end
end

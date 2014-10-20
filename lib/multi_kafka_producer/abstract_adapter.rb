module MultiKafkaProducer
  class AbstractAdapter
    def self.adapter_name(name=nil)
      @name = name if name
      @name
    end

    def self.name
      self.class.adapter_name
    end

    private
    
    def split_msg_pair(msg)
      key, msg = msg
      (msg) ? [key, msg] : [nil, key]
    end
  end
end

module MediaStorage
  class NoMediaStorage < StandardError
    def initialize(*args)
      super("No Storage has been initialized for Panoptes")
    end
  end

  class << self
    delegate :stored_path, :get_path, :put_path, to: :adapter

    def adapter(adapter=nil, opts={})
      if adapter
        @adapter = load_adapter(adapter, opts)
      else
        @adapter ||= default_adapter
      end
    end

    def default_adapter
      raise NoMediaStorage
    end

    def load_adapter(adapter, opts)
      case adapter
      when NilClass, FalseClass
        default_adapter
      when Symbol, String
        load_from_included(adapter).new(**opts)
      when Class
        adapter.new(opts)
      else
        default_adapter
      end
    end

    def load_from_included(adapter)
      case adapter.to_s
      when "aws"
        AwsAdapter
      when "test"
        TestAdapter
      else
        default_adapter
      end
    end
  end
end

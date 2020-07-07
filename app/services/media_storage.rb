require 'media_storage/test_adapter'
require 'media_storage/aws_adapter'
require 'media_storage/azure_adapter'

module MediaStorage
  class EmptyPathError < StandardError; end
  class UnknownContentType < StandardError; end

  class NoMediaStorage < StandardError
    def initialize(*args)
      super("No Storage has been initialized for Panoptes")
    end
  end

  class << self
    delegate :stored_path, :get_path, :put_path, :put_file, :delete_file, to: :adapter

    def adapter(adapter=nil, opts={})
      if adapter
        @adapter = load_adapter(adapter, opts)
        load_azure_and_aws(opts)
      else
        @adapter ||= default_adapter
      end
    end

    def get_adapter
      @adapter
    end

    def set_adapter(user)
      @adapter =  if Panoptes.flipper[:use_azure_storage].enabled? user
                    @azure_adapter
                  else
                    @aws_adapter
                  end
    end

    private

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
      when 'azure'
        AzureAdapter
      when "aws"
        AwsAdapter
      when "test"
        TestAdapter
      else
        default_adapter
      end
    end

    def load_azure_and_aws(opts)
      case @adapter
      when AzureAdapter
        @azure_adapter = @adapter
      when AwsAdapter
        @aws_adapter = @adapter
      end

      @azure_adapter ||= AzureAdapter.new(**opts)
      @aws_adapter ||= AwsAdapter.new(**opts)
    end
  end
end

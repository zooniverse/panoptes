require 'media_storage/test_adapter'
require 'media_storage/aws_adapter'

module Warehouse
  class UnknownAdapter < StandardError; end
  class Uninitialized < StandardError; end

  class << self
    def config(adapter_name, opts = {})
      @adapter = adapter_class(adapter_name).new(opts)
    end

    def adapter
      @adapter or raise Uninitialized
    end

    def store(path, file_path)
      adapter.put_file(path, file_path)
    end

    delegate :put_file, to: :adapter

    private

    def adapter_class(name)
      {
        "aws" => MediaStorage::AwsAdapter,
        "disk" => MediaStorage::DiskAdapter,
        "test" => MediaStorage::TestAdapter
      }.fetch(name.to_s) { raise UnknownAdapter }
    end
  end
end

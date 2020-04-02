# frozen_string_literal: true

module Panoptes
  module StorageAdapter
    def self.configuration
      @configuration ||=
        {
          adapter: ENV.fetch('STORAGE_ADAPTER', 'test'),
          bucket: ENV['STORAGE_BUCKET'],
          prefix: ENV['STORAGE_PREFIX']
        }
    end
  end
end

MediaStorage.adapter(
  Panoptes::StorageAdapter.configuration[:adapter],
  **Panoptes::StorageAdapter.configuration.except(:adapter)
)

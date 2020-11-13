# frozen_string_literal: true

module Panoptes
  module StorageAdapter
    def self.configuration
      @configuration ||=
        {
          adapter: ENV.fetch('STORAGE_ADAPTER', 'test'),
          url_prefix: ENV['STORAGE_URL'],
          # s3 adapter specific
          prefix: ENV['STORAGE_PREFIX'],
          bucket: ENV['STORAGE_BUCKET'],
          # azure adapter specific
          azure_storage_account: ENV.fetch('AZURE_STORAGE_ACCOUNT', 'panoptes'),
          azure_storage_access_key: ENV['AZURE_STORAGE_ACCESS_KEY'],
          azure_storage_container_public: ENV['AZURE_STORAGE_CONTAINER_PUBLIC'],
          azure_storage_container_private: ENV['AZURE_STORAGE_CONTAINER_PRIVATE']
        }
    end
  end
end

MediaStorage.adapter(
  Panoptes::StorageAdapter.configuration[:adapter],
  **Panoptes::StorageAdapter.configuration.except(:adapter)
)

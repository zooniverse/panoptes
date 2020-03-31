module Panoptes
  module StorageAdapter
    def self.configuration
      @configuration ||=
        {
          adapter: ENV['STORAGE_ADAPTER'] || 'test',
          bucket: ENV['STORAGE_BUCKET'],
          prefix: ENV['STORAGE_PREFIX']
        }
    end
  end
end

config = Panoptes::StorageAdapter.configuration
MediaStorage.adapter(config[:adapter], **config.except(:adapter))

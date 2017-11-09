module Panoptes
  module StorageAdapter
    def self.configuration
      return @configuration if @configuration
      begin
        file = Rails.root.join('config/storage.yml')
        @configuration = YAML.load(File.read(file))[Rails.env].symbolize_keys
        @configuration.freeze
      rescue Errno::ENOENT, NoMethodError
        {adapter: "default"}
      end
    end
  end
end

config = Panoptes::StorageAdapter.configuration
MediaStorage.adapter(config[:adapter], **config.except(:adapter))

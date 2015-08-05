require 'ostruct'
module Panoptes
  def self.cors_config
    @cors_config ||=OpenStruct
      .new(**begin
        file = Rails.root.join('config/cors_config.yml')
        YAML.load(File.read(file))[Rails.env].symbolize_keys
      rescue Errno::ENOENT, NoMethodError
        {  }
      end)
  end
end

Panoptes.cors_config

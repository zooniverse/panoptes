module Panoptes
  module ClassificationHeartbeat
    def self.config
      @config ||= begin
                    file = Rails.root.join('config/heartbeat_config.yml')
                    YAML.load(File.read(file))[Rails.env].symbolize_keys
                  rescue Errno::ENOENT, NoMethodError
                    {  }
                  end
    end

    def self.window_period
      config.fetch(:window_period, nil)
    end

    def self.emails
      config.fetch(:emails, [])
    end

    def self.check_interval
      config.fetch(:check_interval, nil)
    end
  end
end

Panoptes::ClassificationHeartbeat.config

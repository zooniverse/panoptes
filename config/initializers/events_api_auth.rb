module Panoptes
  module EventsApi
    def self.auth
      @events_api_auth ||= begin
                         file = Rails.root.join('config/events_api_auth.yml')
                         YAML.load(File.read(file))[Rails.env].symbolize_keys
                       rescue Errno::ENOENT, NoMethodError
                         {  }
                       end
    end

    def self.username
      auth[:username]
    end

    def self.password
      auth[:password]
    end
  end
end

Panoptes::EventsApi.auth

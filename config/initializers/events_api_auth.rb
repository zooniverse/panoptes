module Panoptes
  module EventsApi
    def self.auth
      @events_api_auth ||=
        {
          username: ENV['EVENTS_API_USERNAME'] || 'dev',
          password: ENV['EVENTS_API_PASSWORD'] || 'dev_password'
        }
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

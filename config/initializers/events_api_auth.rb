# frozen_string_literal: true

module Panoptes
  module EventsApi
    def self.username
      ENV.fetch('EVENTS_API_USERNAME', 'dev')
    end

    def self.password
      ENV.fetch('EVENTS_API_PASSWORD', 'dev_password')
    end
  end
end

Panoptes::EventsApi.auth

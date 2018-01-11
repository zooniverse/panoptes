module Logging
  module GraylogDefaults
    def self.config
      [
        ENV.fetch("GRAYLOG_HOST_NAME", "graylog.zooniverse.org"),
        ENV.fetch("GRAYLOG_HOST_PORT", 12201),
        ENV.fetch("GRAYLOG_UPD_CHUNK_CONFIG", "WAN"),
        { host: app_source_name }
      ]
    end

    # the source name that appears in graylog UI
    def self.app_source_name
      suffix = if !Rails.env.production?
                "rails"
               else
                "#{Rails.env}-rails"
               end
      ENV.fetch("GRAYLOG_SOURCE_NAME", "panoptes-api-#{suffix}")
    end

    # TODO: add sidekiq logger for gelf / or just drop it and
    # and keep them in stdout
    # https://github.com/mperham/sidekiq/wiki/Logging#customize-logger
    # also https://github.com/layervault/sidekiq-gelf-rb
    # but that hooks into job middleware and should be thread safe
    # i'd prefer to use a single instance vs one for each job that runs
    # but maybe that won't scale out
  end
end

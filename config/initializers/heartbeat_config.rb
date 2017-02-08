module Panoptes
  module ClassificationHeartbeat
    def self.window_period
      @lifecycled_live_window ||= ENV.fetch("HEARTBEAT_WINDOW_PERIOD", 15).to_i
    end

    def self.emails
      @emails ||= ENV.fetch("HEARTBEAT_EMAILS", "no-reply@zooniverse.org")
    end
  end
end

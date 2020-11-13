# frozen_string_literal: true

module Panoptes
  module RateLimitDumpWorker
    def self.interval
      ENV.fetch('DUMP_CONGESTION_OPTS_INTERVAL', 86400).to_i
    end

    def self.max_in_interval
      ENV.fetch('DUMP_CONGESTION_OPTS_MAX_IN_INTERVAL', 1).to_i
    end

    def self.min_delay
      ENV.fetch('DUMP_CONGESTION_OPTS_MIN_DELAY', 43200).to_i
    end

    def self.reject_with
      ENV.fetch('DUMP_CONGESTION_OPTS_REJECT_WITH', 'cancel').to_sym
    end

    def self.skip_rate_limit_user_ids
      skip_id_env = ENV.fetch('SKIP_DUMP_RATE_LIMIT_USER_IDS', '')
      skip_id_env.split(',').map(&:to_i)
    end
  end
end

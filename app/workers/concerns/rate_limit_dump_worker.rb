# frozen_string_literal: true

module RateLimitDumpWorker
  extend ActiveSupport::Concern

  included do
    sidekiq_options congestion:
      {
        interval: ENV.fetch('DUMP_CONGESTION_OPTS_INTERVAL', 86400).to_i,
        max_in_interval: ENV.fetch('DUMP_CONGESTION_OPTS_MAX_IN_INTERVAL', 1).to_i,
        min_delay: ENV.fetch('DUMP_CONGESTION_OPTS_MIN_DELAY', 43200).to_i,
        reject_with: ENV.fetch('DUMP_CONGESTION_OPTS_REJECT_WITH', 'cancel').to_sym,
        key: ->(resource_id, resource_type, medium_id, _requester_id=nil) {
          "#{resource_type}_#{resource_id}_#{medium_id}_data_dump_worker"
        },
        enabled: ->(_resource_id, _resource_type, _medium_id, requester_id=nil) {
          congestion_enabled?(requester_id)
        }
      }
  end

  module ClassMethods
    def congestion_enabled?(requester_id)
      # if the user is missing, should only happen via the rails console
      return false if requester_id.blank?

      if (skip_id_env = ENV.fetch('SKIP_DUMP_RATE_LIMIT_USER_IDS', nil))
        skip_ids = skip_id_env.split(',').map(&:to_i)
        skip_ids.include?(requester_id)
        # false if the user is a special skip rate limit user
        false
      else
        # false if user is admin, true if not admin
        !User.find(requester_id).is_admin?
      end
    end
  end
end

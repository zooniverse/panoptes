module RateLimitDumpWorker
  extend ActiveSupport::Concern

  included do
    sidekiq_options congestion:
      {
        interval: ENV.fetch('DUMP_CONGESTION_OPTS_INTERVAL', 86400),
        max_in_interval: ENV.fetch('DUMP_CONGESTION_OPTS_MAX_IN_INTERVAL', 1),
        min_delay: ENV.fetch('DUMP_CONGESTION_OPTS_MIN_DELAY', 43200),
        reject_with: ENV.fetch('DUMP_CONGESTION_OPTS_REJECT_WITH', 'cancel').to_sym,
        key: ->(resource_id, resource_type, medium_id, _requester_id=nil) {
          "#{resource_type}_#{resource_id}_#{medium_id}_data_dump_worker"
        },
        enabled: ->(_resource_id, _resource_type, _medium_id, requester_id=nil) {
          requester_id.blank? || !User.find(requester_id).admin?
        }
      }
  end
end

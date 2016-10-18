module RateLimitDumpWorker
  extend ActiveSupport::Concern

  included do
    sidekiq_options congestion: Panoptes::CongestionControlConfig.dump_worker.congestion_opts.merge({
      key: ->(resource_id, resource_type, medium_id, requester_id = nil) {
        "#{resource_type}_#{resource_id}_#{medium_id}_data_dump_worker"
      },
      enabled: ->(resource_id, resource_type, medium_id, requester_id = nil) {
        requester_id.blank? || !User.find(requester_id).admin?
      }
    })
  end
end

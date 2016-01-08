module RateLimitDumpWorker
  extend ActiveSupport::Concern

  included do
    sidekiq_options congestion: Panoptes::CongestionControlConfig.dump_worker.congestion_opts.merge({
      key: ->(project_id, medium_id, requester_id = nil) {
        "project_#{ project_id }_#{medium_id}_data_dump_worker"
      },
      enabled: ->(project_id, medium_id, requester_id = nil) {
        requester_id.blank? || !User.find(requester_id).admin?
      }
    })
  end
end

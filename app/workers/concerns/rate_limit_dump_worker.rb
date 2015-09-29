module RateLimitDumpWorker
  extend ActiveSupport::Concern

  included do
    sidekiq_options congestion: Panoptes::DumpWorker.congestion_opts.merge({
      key: ->(project_id, medium_id) {
        "project_#{ project_id }_#{medium_id}_data_dump_worker"
      }
    })
  end
end

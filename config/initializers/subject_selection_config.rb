module Panoptes
  module SubjectSelection
    def self.config
      @config ||=
        {
          focus_set_window_size: ENV['SELECTION_FOCUS_SET_WINDOW_SIZE'] || 1000,
          index_rebuild_rate: ENV['SELECTION_INDEX_REBUILD_RATE'] || 0.01,
          random_order_shuffle_worker_opts:
            {
              interval: ENV['SELECTION_RANDOM_INTERVAL'] || 60,
              max_in_interval: ENV['SELECTION_RANDOM_MAX_IN_INTERVAL'] || 1,
              MIN_DELAY: ENV['selection_RANDOM_MIN_DELAY'] || 30,
              reject_with: :cancel
            }
        }
    end

    def self.focus_set_window_size
      config[:focus_set_window_size]
    end

    def self.index_rebuild_rate
      config[:index_rebuild_rate]
    end

    def self.random_order_shuffle_worker_opts
      config.fetch(:random_order_shuffle_worker_opts, {}).symbolize_keys
    end
  end
end

Panoptes::SubjectSelection.config

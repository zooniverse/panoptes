module Panoptes
  module SubjectSelection
    def self.config
      @config ||= begin
                    file = Rails.root.join('config/subject_selection_config.yml')
                    YAML.load(File.read(file))[Rails.env].symbolize_keys
                  rescue Errno::ENOENT, NoMethodError
                    {  }
                  end
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

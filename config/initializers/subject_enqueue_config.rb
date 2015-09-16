module Panoptes
  module SubjectEnqueue
    def self.config
      @config ||= begin
                    file = Rails.root.join('config/subject_enqueue_config.yml')
                    YAML.load(File.read(file))[Rails.env].symbolize_keys
                  rescue Errno::ENOENT, NoMethodError
                    {  }
                  end
    end

    def self.congestion_opts
      config.fetch(:congestion_opts, {}).symbolize_keys
    end
  end
end

Panoptes::SubjectEnqueue.config

module Panoptes
  module CongestionControlConfig
    class CongestionConfig
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def congestion_opts
        config.fetch(:congestion_opts, {}).symbolize_keys
      end
    end

    def self.load
      [:counter_worker, :dump_worker].each do |worker|
        config = load_config.fetch(worker, {}).symbolize_keys
        singleton_class.class_eval do
          define_method worker do
            CongestionConfig.new(config)
          end
        end
      end
    end

    def self.load_config
      @config ||= begin
                    file = Rails.root.join('config/congestion_control_config.yml')
                    YAML.load(File.read(file))[Rails.env].symbolize_keys
                  rescue Errno::ENOENT, NoMethodError
                    {  }
                  end
    end
  end
end

Panoptes::CongestionControlConfig.load

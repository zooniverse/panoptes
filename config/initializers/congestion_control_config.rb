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
      @config ||= { :dump_worker =>
                    {"congestion_opts" =>
                      {
                        "interval" => ENV['DUMP_CONGESTION_OPTS_INTERVAL'] || 86400,
                        "max_in_interval" => ENV['DUMP_CONGESTION_OPTS_MAX_IN_INTERVAL'] || 1,
                        "min_delay" => ENV['DUMP_CONGESTION_OPTS_MIN_DELAY'] || 43200,
                        "reject_with" => (ENV['DUMP_CONGESTION_OPTS_REJECT_WITH']&.to_sym || :cancel)
                      }
                    },
                  :counter_worker =>
                    {"congestion_opts"=>
                      {
                        "interval" => ENV['COUNTER_CONGESTION_OPTS_INTERVAL'] || 360,
                        "max_in_interval" => ENV['COUNTER_CONGESTION_OPTS_MAX_IN_INTERVAL'] || 10,
                        "min_delay" => ENV['COUNTER_CONGESTION_OPTS_MIN_DELAY'] || 180,
                        "reject_with" => (ENV['COUNTER_CONGESTION_OPTS_REJECT_WITH']&.to_sym || :cancel)
                      }
                    }
                }
    end
  end
end

Panoptes::CongestionControlConfig.load

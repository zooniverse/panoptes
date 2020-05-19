module Configurable
  extend ActiveSupport::Concern

  included do
    cattr_accessor :host, :user_id, :application_id
  end

  module ClassMethods
    def configure(key, options = {})
      @fields ||= {}
      @fields[key] = options
      cattr_accessor key
    end

    def config_file=(file_name)
      @config_file = "config/#{file_name}.yml"
    end

    def api_prefix=(prefix)
      @api_prefix = prefix.upcase
    end

    def load_configuration
      @fields.each do |key, options|
        field_key = options[:key] || key
        value = env_vars["#{@api_prefix}_#{field_key.upcase}"]
        value ||= config_from_file[field_key]
        value = value.to_i if options[:type] == :integer

        self.public_send("#{key}=", value)
      end
    end

    def config_from_file
      @config_from_file ||=
        begin
          config = YAML.safe_load(
            ERB.new(File.read(Rails.root.join(@config_file))).result
          )
          config[Rails.env].symbolize_keys
        rescue Errno::ENOENT, NoMethodError
          {}
        end
    end

    def env_vars
      ENV
    end
  end
end

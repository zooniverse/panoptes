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
        value = ENV["#{@api_prefix}_#{key.upcase}"]
        value ||= configuration[options[:file_field || key]]
        value = value.to_i if options[:type] == :integer

        self.public_send("#{key}=", value)
      end
    end

    def configuration
      @configuration ||= begin
                           config = YAML.load(ERB.new(File.read(Rails.root.join(@config_file))).result)
                           config[Rails.env].symbolize_keys
                         rescue Errno::ENOENT, NoMethodError
                           {  }
                         end
    end
  end
end

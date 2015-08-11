module Configurable
  extend ActiveSupport::Concern

  included do
    cattr_accessor :host, :user_id, :application_id
  end

  module ClassMethods
    def config_file=(file_name)
      @config_file = "config/#{file_name}.yml"
    end

    def api_prefix=(prefix)
      @api_prefix = prefix.upcase
    end

    def load_configuration
      self.host = ENV["#{@api_prefix}_API_HOST"] || configuration[:host]
      self.user_id = (ENV["#{@api_prefix}_API_USER"] || configuration[:user]).to_i
      self.application_id = (ENV["#{@api_prefix}_API_APPLICATION"] || configuration[:application]).to_i
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

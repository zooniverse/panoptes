class AggregationClient
  extend Configurable

  self.config_file = "aggregation_api"

  cattr_accessor :host

  def self.configure
    self.host = ENV['AGGREGATION_ENGINE_HOST'] || configuration[:host]
    self.user_id = (ENV['AGGREGATION_ENGINE_USER'] || configuration[:user]).to_i
    self.application_id = (ENV['AGGREGATION_ENGINE_APPLICATION'] || configuration[:application]).to_i
  end

  attr_reader :connection

  def initialize
    @connection = connect!
  end

  def connect!
    Faraday.new host do |faraday|
      faraday.response :json, content_type: /\bjson$/
      faraday.use :http_cache, store: Rails.cache, logger: Rails.logger
      faraday.adapter(*adapter)
    end
  end

  def generate_token
    Doorkeeper::AccessToken.create! do |ac|
      ac.resource_owner_id = user_id
      ac.application_id = application_id
      ac.expires_in = 1.day
      ac.scopes = "media public"
    end
  end

  def aggregate(project, medium)
    body = {
      project_id: project.id,
      url: medium.put_file,
      token: generate_token
    }

    connection.post('/') do |req|
      req.headers["Accept"] = "application/json"
      req.headers["Content-Type"] = "application/json"
      req.body = body.to_json
    end
  end
end

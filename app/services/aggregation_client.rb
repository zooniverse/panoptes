class AggregationClient
  include Configurable

  self.config_file = "aggregation_api"
  self.api_prefix = "aggregation"

  attr_reader :connection

  def initialize(adapter = Faraday.default_adapter)
    @connection = connect!(adapter)
  end

  def connect!(adapter)
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
      ac.scopes = "medium project public"
    end
  end

  def body(project, medium)
    {
      project_id: project.id,
      medium_href: medium.location,
      metadata: medium.metadata,
      token: generate_token.token
    }
  end

  def aggregate(project, medium)
    connection.post('/') do |req|
      req.headers["Accept"] = "application/json"
      req.headers["Content-Type"] = "application/json"
      req.body = body(project, medium).to_json
    end
  end
end

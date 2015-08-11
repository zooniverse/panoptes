class TalkApiClient
  include Configurable

  self.config_file = "talk_api"
  self.api_prefix = "talk"

  class NoTalkHostError < StandardError
  end

  class JSONAPIResource
    attr_reader :type, :href, :connection
    def initialize(connection, type, href)
      @type, @href, @connection = type, href, connection
    end

    def update
      raise NotImplementedError
    end

    def create(attrs={})
      connection.request('post', href) do |req|
        req.body = {@type => attrs}.to_json
      end
    end

    def destroy
      raise NotImplementedError
    end

    def show
      raise NotImplementedError
    end

    def index
      raise NotImplementedError
    end
  end

  attr_reader :connection, :token

  def initialize(adapter = Faraday.default_adapter)
    unless host
      raise NoTalkHostError, "A talk instance has not been configured for #{Rails.env} environment"
    end
    @resources = {}.with_indifferent_access
    create_token
    create_connection(adapter)
    initial_request
  end

  def create_token
    @token = Doorkeeper::AccessToken.create! do |ac|
      ac.resource_owner_id = user_id
      ac.application_id = application_id
      ac.expires_in = 1.day
      ac.scopes = "public user project"
    end
  end

  def create_connection(adapter)
    @connection = Faraday.new host do |faraday|
      faraday.response :json, content_type: /\bjson$/
      faraday.use :http_cache, store: Rails.cache, logger: Rails.logger
      faraday.adapter(*adapter)
    end
  end

  def initial_request
    request('get', '').body.each do |_, resource|
      @resources[resource['type']] = JSONAPIResource.new(self, resource['type'], resource['href'])
    end
  end

  def request(method, path, *args)
    connection.send(method, path, *args) do |req|
      req.headers["Accept"] = "application/vnd.api+json"
      req.headers["Content-Type"] = "application/json"
      req.headers["Authorization"] = "Bearer #{token.token}"
      yield req if block_given?
    end
  end

  def method_missing(name, *args, &block)
    if resource = @resources[name]
      resource
    else
      super
    end
  end
end

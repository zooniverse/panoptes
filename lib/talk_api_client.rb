class TalkApiClient
  class JSONAPIResource
    attr_reader :type, :href, :connection
    def initialize(connection, type, href)
      @type, @href, @connection = type, href, connection
    end

    def update
      raise NotImplementedError
    end

    def create(attrs={})
      connection.request('POST', href) do |req|
        req.body = attrs.to_json
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

  cattr_accessor :host, :user_id, :application_id

  def self.load_configuration
    self.host = ENV['TALK_API_HOST'] || configuration[:host]
    self.user_id = (ENV['TALK_API_USER'] || configuration[:user]).to_i
    self.application_id = (ENV['TALK_API_APPLICATION'] || configuration[:application]).to_i
  end

  def self.configuration
    @configuration ||= begin
                         config = YAML.load(ERB.new(File.read(Rails.root.join('config/talk_api.yml'))).result)
                         config[Rails.env].symbolize_keys
                       rescue Errno::ENOENT, NoMethodError
                         {  }
                       end
  end

  attr_reader :connection, :token

  def initialize(adapter = nil)
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
    end
  end

  def create_connection(adapter = Faraday.default_adapter)
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
      req.headers["Authorization"] = "Bearer #{token}"
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

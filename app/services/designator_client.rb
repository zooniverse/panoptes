class DesignatorClient
  include Configurable

  class GenericError < StandardError; end
  class ConnectionFailed < GenericError; end
  class ResourceNotFound < GenericError; end
  class ServerError < GenericError; end

  self.config_file = "designator_api"
  self.api_prefix = "designator_api"

  configure :host
  configure :username
  configure :password

  attr_reader :connection

  def initialize(adapter = Faraday.default_adapter)
    @connection = connect!(adapter)
  end

  def connect!(adapter)
    Faraday.new(host, ssl: {verify: false}) do |faraday|
      faraday.request  :basic_auth, username, password
      faraday.response :json, content_type: /\bjson$/
      faraday.adapter(*adapter)
    end
  end

  def add_seen(workflow_id, user_id, subject_id)
    request(:put, "/api/users/#{user_id}/add_seen_subject") do |req|
      req.body = {
        workflow_id: workflow_id,
        subject_id: subject_id
      }.to_json
    end
  end

  def load_user(workflow_id, user_id)
    # not needed right now
    true
  end

  def reload_workflow(workflow_id)
    request(:post, "/api/workflows/#{workflow_id}/reload")
  end

  def remove_subject(subject_id, workflow_id)
    request(:post, "/api/workflows/#{workflow_id}/remove") do |req|
      req.body = {subject_id: subject_id}.to_json
    end
  end

  def get_subjects(workflow_id, user_id, subject_set_id, limit)
    url = "/api/workflows/#{workflow_id}"
    params = { user_id: user_id, subject_set_id: subject_set_id, limit: limit }.compact
    request(:get, [ url, params ])
  end

  private

  def request(http_method, params)
    response = connection.send(http_method, *params) do |req|
      req.headers["Accept"] = "application/json"
      req.headers["Content-Type"] = "application/json"
      req.options.timeout = 5           # open/read timeout in seconds
      req.options.open_timeout = 2      # connection open timeout in seconds
      yield req if block_given?
    end

    handle_response(response)
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => exception
    raise GenericError.new(exception.message)
  end

  def handle_response(response)
    case response.status
    when 404
      raise ResourceNotFound, status: response.status, body: response.body
    when 400..600
      raise ServerError.new(response.body)
    else
      response.body
    end
  end
end

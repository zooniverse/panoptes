# frozen_string_literal: true

class AggregationClient
  class ConnectionError < StandardError; end
  class ResourceNotFound < ConnectionError; end
  class ServerError < ConnectionError; end

  attr_reader :connection, :host

  def initialize(adapter=Faraday.default_adapter)
    @host = ENV.fetch('AGGREGATION_HOST', 'https://aggregation-staging.zooniverse.org')
    @connection = connect!(adapter)
  end

  def connect!(adapter)
    Faraday.new(host, ssl: { verify: false }) do |faraday|
      faraday.response :json, content_type: /\bjson$/
      faraday.adapter(*adapter)
    end
  end

  def send_aggregation_request(project_id, workflow_id, user_id)
    params = { project_id: project_id, workflow_id: workflow_id, user_id: user_id }

    request(:post, '/run_aggregation') do |req|
      req.body = params.to_json
    end
  end

  private

  def request(http_method, params)
    response = connection.send(http_method, *params) do |req|
      req.headers['Accept'] = 'application/json'
      req.headers['Content-Type'] = 'application/json'
      req.options.timeout = 5      # open/read timeout in seconds
      req.options.open_timeout = 2 # connection open timeout in seconds
      yield req if block_given?
    end

    handle_response(response)
  rescue Faraday::TimeoutError,
         Faraday::ConnectionFailed => e
    raise ConnectionError, e.message
  end

  def handle_response(response)
    case response.status
    when 404
      raise ResourceNotFound, status: response.status, body: response.body
    when 400..600
      raise ServerError, response.body
    else
      response.body
    end
  end
end

class CellectExClient
  include Configurable

  class GenericError < StandardError; end
  class ConnectionFailed < GenericError; end
  class ResourceNotFound < GenericError; end
  class ServerError < GenericError; end

  self.config_file = "cellect_ex_api"
  self.api_prefix = "cellect_ex_api"

  configure :host

  attr_reader :connection

  def initialize(adapter = Faraday.default_adapter)
    @connection = connect!(adapter)
  end

  def connect!(adapter)
    Faraday.new(host, ssl: {verify: false}) do |faraday|
      faraday.response :json, content_type: /\bjson$/
      faraday.adapter(*adapter)
    end
  end

  def add_seen(workflow_id, user_id, subject_id)
    # not needed right now
    true
  end

  def load_user(workflow_id, user_id)
    # not needed right now
    true
  end

  def reload_workflow(workflow_id)
    response = connection.post("/api/workflows/#{workflow_id}/reload") do |req|
      req.headers["Accept"] = "application/json"
      req.headers["Content-Type"] = "application/json"
    end

    handle_response(response)
  end

  def remove_subject(subject_id, workflow_id, group_id)
    response = connection.post("/api/workflows/#{workflow_id}/remove") do |req|
      req.headers["Accept"] = "application/json"
      req.headers["Content-Type"] = "application/json"
      req.body = {subject_id: subject_id}.to_json
    end

    handle_response(response)
  end

  def get_subjects(workflow_id, user_id, _group_id, limit)
    response = connection.get("/api/workflows/#{workflow_id}", strategy: :weighted, user_id: user_id, limit: limit) do |req|
      req.headers["Accept"] = "application/json"
      req.options.timeout = 5           # open/read timeout in seconds
      req.options.open_timeout = 2      # connection open timeout in seconds
    end

    handle_response(response)
  rescue Faraday::TimeoutError => exception
    raise GenericError.new(exception.message)
  end

  private

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

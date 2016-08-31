class CellectExClient
  include Configurable

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
    connection.post("/api/workflows/#{workflow_id}/reload") do |req|
      req.headers["Accept"] = "application/json"
      req.headers["Content-Type"] = "application/json"
    end.body
  end

  def remove_subject(subject_id, workflow_id, group_id)
    connection.post("/api/workflows/#{workflow_id}/remove") do |req|
      req.headers["Accept"] = "application/json"
      req.headers["Content-Type"] = "application/json"
      req.body = {subject_id: subject_id}.to_json
    end.body
  end

  def get_subjects(workflow_id, user_id, _group_id, limit)
    connection.get("/api/workflows/#{workflow_id}", strategy: :weighted, user_id: user_id, limit: limit) do |req|
      req.headers["Accept"] = "application/json"
    end.body
  end
end

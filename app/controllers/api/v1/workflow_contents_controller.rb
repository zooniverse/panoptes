class Api::V1::WorkflowContentsController < Api::ApiController
  include Versioned

  require_authentication :all, scopes: [:project]
  resource_actions :default
  schema_type :json_schema
end

class Api::V1::WorkflowContentsController < Api::ApiController
  include Versioned
  include JsonApiController::PunditPolicy

  require_authentication :all, scopes: [:project]
  resource_actions :default
  schema_type :json_schema
end

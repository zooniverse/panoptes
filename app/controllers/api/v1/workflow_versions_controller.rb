class Api::V1::WorkflowVersionsController < Api::ApiController
  include JsonApiController::PunditPolicy

  require_authentication :all, scopes: [:project]

  resource_actions :index, :show

  schema_type :json_schema
end

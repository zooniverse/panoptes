class Api::V1::SubjectSetsController < Api::ApiController
  include JsonApiController
  
  doorkeeper_for :create, :update, :destroy, scopes: [:project]
  resource_actions :default
  schema_type :json_schema

  allowed_params :create
  allowed_params :update
end

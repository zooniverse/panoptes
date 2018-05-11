class Api::V1::SubjectSetImportsController < Api::Controller
  require_authentication :create, scopes: [:project]

  resource_actions :index, :show, :create

  schema_type :json_schema
end

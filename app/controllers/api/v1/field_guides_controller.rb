class Api::V1::FieldGuidesController < Api::ApiController
  doorkeeper_for :update, :create, :destroy, scopes: [:project]

  resource_actions :default

  schema_type :json_schema
end

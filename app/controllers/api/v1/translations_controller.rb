class Api::V1::TranslationsController < Api::ApiController
  # require_authentication :update, :destroy, scopes: [:group]
  resource_actions :show, :index, :update, :create
  schema_type :json_schema
end

class Api::V1::OrganizationContentsController < Api::ApiController
  include Versioned

  require_authentication :all, scopes: [:project]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, :language, :title,
    *Api::V1::OrganizationsController::CONTENT_PARAMS, links: [:organization]

  allowed_params :update, :title, *Api::V1::OrganizationsController::CONTENT_PARAMS
end

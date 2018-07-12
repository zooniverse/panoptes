class Api::V1::OrganizationContentsController < Api::ApiController
  include JsonApiController::PunditPolicy
  include Versioned

  require_authentication :all, scopes: [:organization]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, :language, *Api::V1::OrganizationsController::CONTENT_PARAMS, links: [:organization]

  allowed_params :update, *Api::V1::OrganizationsController::CONTENT_PARAMS
end

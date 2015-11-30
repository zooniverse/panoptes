class Api::V1::ProjectContentsController < Api::ApiController
  include Versioned

  require_authentication :all, scopes: [:project]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, :language, :title,
    *Api::V1::ProjectsController::CONTENT_PARAMS, links: [:project]

  allowed_params :update, :title, *Api::V1::ProjectsController::CONTENT_PARAMS
end

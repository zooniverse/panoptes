class Api::V1::ProjectContentsController < Api::ApiController
  include JsonApiController
  include Versioned

  doorkeeper_for :all, scopes: [:project]
  resource_actions :default

  allowed_params :create, :language, :title,
    *Api::V1::ProjectsController::CONTENT_PARAMS, links: [:project]

  allowed_params :update, :title, *Api::V1::ProjectsController::CONTENT_PARAMS
end

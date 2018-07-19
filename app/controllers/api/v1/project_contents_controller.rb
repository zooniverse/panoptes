class Api::V1::ProjectContentsController < Api::ApiController
  include JsonApiController::PunditPolicy
  include Versioned

  CONTENT_PARAMS = [
    :title,
    :description,
    :workflow_description,
    :introduction,
    :researcher_quote
  ].freeze

  require_authentication :all, scopes: [:project]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, :language, :title, *CONTENT_PARAMS, links: [:project]

  allowed_params :update, :title, *CONTENT_PARAMS
end

class Api::V1::ProjectPagesController < Api::ApiController
  PARENT_RESOURCE = :project

  include JsonApiController::PunditPolicy
  include Pages
end

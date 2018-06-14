class Api::V1::ProjectPagesController < Api::ApiController
  PARENT_RESOURCE = :project

  include JsonApiController::LegacyPolicy
  include Pages
end

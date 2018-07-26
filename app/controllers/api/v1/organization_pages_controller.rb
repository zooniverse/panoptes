class Api::V1::OrganizationPagesController < Api::ApiController
  PARENT_RESOURCE = :organization

  include JsonApiController::PunditPolicy
  include Pages
end

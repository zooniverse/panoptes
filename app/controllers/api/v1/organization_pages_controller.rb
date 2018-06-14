class Api::V1::OrganizationPagesController < Api::ApiController
  PARENT_RESOURCE = :organization

  include JsonApiController::LegacyPolicy
  include Pages
end

class Api::V1::OrganizationPagesController < Api::ApiController
  PARENT_RESOURCE = :organization.freeze
  include Pages
end

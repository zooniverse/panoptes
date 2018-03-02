class Api::V1::OrganizationPagesController < Api::ApiController
  include RoleControl::RoledController
  PARENT_RESOURCE = :organization
  include Pages
end

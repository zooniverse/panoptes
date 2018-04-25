class Api::V1::OrganizationRolesController < Api::ApiController
  include RoleControl::RoledController
  include RolesController
  require_authentication :create, :update, :destroy, scopes: [:organization]

  allowed_params :create, roles: [], links: [:user, :organization]
  allowed_params :update, roles: []

  def resource_name
    "organization_role"
  end
end

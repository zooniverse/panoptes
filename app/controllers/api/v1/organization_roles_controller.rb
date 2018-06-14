class Api::V1::OrganizationRolesController < Api::ApiController
  include RolesController
  require_authentication :create, :update, :destroy, scopes: [:organization]

  allowed_params :create, roles: [], links: [:user, :organization]
  allowed_params :update, roles: []
end

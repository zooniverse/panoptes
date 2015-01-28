class Api::V1::ProjectRolesController < Api::ApiController
  include RolesController

  doorkeeper_for :all, scopes: [:project]
  schema_type :strong_params
  
  allowed_params :create, roles: [], links: [:user, :project]

  allowed_params :update, roles: []

  def resource_name
    "project_role"
  end
end

class Api::V1::ProjectRolesController < Api::ApiController
  include RolesController
  skip_before_filter :require_login, only: :index
  doorkeeper_for :show, :create, :update, scopes: [:project]
  schema_type :strong_params

  allowed_params :create, roles: [], links: [:user, :project]

  allowed_params :update, roles: []

  def resource_name
    "project_role"
  end
end

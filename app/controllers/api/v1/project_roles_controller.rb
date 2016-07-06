class Api::V1::ProjectRolesController < Api::ApiController
  include RolesController
  require_authentication :create, :update, :destroy, scopes: [:project]

  allowed_params :create, roles: [], links: [:user, :project]
  allowed_params :update, roles: []

  def resource_name
    "project_role"
  end

  def update
    super do
      # user_added_to_project(api_user.id, params[:id], roles) if check_new_roles(roles).present?
      Mailers::UserAddedToProject.run!(api_user: api_user, resource_id: params[:id], roles: roles) if check_new_roles(roles).present?
    end
  end

  private

  # def user_added_to_project(user_id, project_id, roles)
  #   Mailers::UserAddedToProject.run!(user_id: user_id, resource_id: project_id, roles: roles)
  # end

  def roles
    params[:project_roles][:roles]
  end

  def check_new_roles(roles)
    # diff = roles ? roles[1].sort - roles[0].sort : []
    ["collaborator", "expert"] & roles
  end
end

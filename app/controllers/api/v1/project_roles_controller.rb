class Api::V1::ProjectRolesController < Api::ApiController
  include RolesController
  require_authentication :create, :update, :destroy, scopes: [:project]

  allowed_params :create, roles: [], links: [:user, :project]
  allowed_params :update, roles: []

  def resource_name
    "project_role"
  end

  def send_collaborator_email
    UserInfoChangedMailerWorker.perform_async(id, resource.id, check_new_roles(params)) if check_new_roles(params).present?
  end

  private

  def check_new_roles(roles)
    diff = roles ? roles[1].sort - roles[0].sort : []
    ["collaborator", "expert"] & diff
  end
end

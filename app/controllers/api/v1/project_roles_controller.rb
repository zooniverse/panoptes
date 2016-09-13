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
      logger.info "Role Mailer Debug: new_roles_present(#{roles.inspect})? == #{new_roles_present?(roles)}"
      UserAddedToProjectMailerWorker.perform_async(api_user.id, params[:id], roles) if new_roles_present?(roles)
    end
  end

  private

  def roles
    params[:project_roles][:roles]
  end

  def new_roles_present?(roles)
    return false unless roles.present?
    (["collaborator", "expert"] & roles).present?
  end
end

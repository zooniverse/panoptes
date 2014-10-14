class Api::V1::ProjectRolesController < Api::ApiController
  include JsonApiController
  include CreateOrUpdate

  prepend_before_filter :require_login
  doorkeeper_for :all, scopes: [:project]
  access_control_for [:update, :update_roles]
  
  resource_actions :index, :show, :create, :update

  allowed_params :create, roles: [], links: [:user, :project]

  allowed_params :update, roles: []

  private

  def should_update?
    super(create_params[:links])
  end

  def serializer
    UserProjectRoleSerializer
  end

  def resource_name
    "project_role"
  end

  def resource_class
    UserProjectPreference
  end

  def visible_scope
    UserProjectPreference.visible_to(api_user)
  end
  
  def new_items(relation, value)
    if relation == "project"
      super(relation, value, :roles)
    else
      super
    end
  end
end

class Api::V1::ProjectRolesController < Api::ApiController
  include JsonApiController

  prepend_before_filter :require_login
  doorkeeper_for :all, scopes: [:project]
  access_control_for [:update, :update_roles]
  
  resource_actions :index, :show, :create, :update

  allowed_params :create, roles: [], links: [:user, :project]

  allowed_params :update, roles: []
  
  def create
    if should_update?
      fake_update
    else
      super
    end
  end

  private

  def fake_update
    unless controlled_resource.roles.empty?
      raise Api::RolesExist.new
    end
    
    ActiveRecord::Base.transaction do
      build_resource_for_update(create_params.except(:links))
      controlled_resource.save!
    end
    
    if controlled_resource.persisted?
      created_resource_response(controlled_resource)
    end 
  end
  
  def should_update?
    find_params = create_params[:links].symbolize_keys
    @controlled_resource = resource_class.find_by(**find_params)
    return unless @controlled_resource
    controlled_resource.can_update_roles?(api_user)
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

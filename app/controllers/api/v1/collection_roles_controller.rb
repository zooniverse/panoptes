class Api::V1::CollectionRolesController < Api::ApiController
  include JsonApiController

  prepend_before_filter :require_login
  doorkeeper_for :all, scopes: [:collection]
  access_control_for [:update, :update_roles]

  resource_actions :index, :show, :create_or_update, :update

  allowed_params :create, roles: [], links: [:user, :collection]
  allowed_params :update, roles: []

  def serializer
    UserCollectionRoleSerializer
  end

  def resource_name
    "collection_role"
  end

  def resource_class
    UserCollectionPreference
  end

  def visible_scope
    UserCollectionPreference.visible_to(api_user)
  end

  def can_create_or_update?
    :can_update_roles?
  end

  def new_items(relation, value)
    if relation == "project"
      super(relation, value, :roles)
    else
      super
    end
  end
end

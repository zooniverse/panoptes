class Api::V1::GroupsController < Api::ApiController
  doorkeeper_for :index, :show, scopes: [:public]
  doorkeeper_for :create, :update, :destroy, scopes: [:group]
  resource_actions :show, :index, :update, :deactivate, :create
  schema_type :strong_params

  setup_access_control_for_groups!

  alias_method :user_group, :controlled_resource
  
  allowed_params :create, :name, :display_name, links: [ users: [] ]
  allowed_params :update, :display_name
  
  private

  def build_resource_for_create(create_params)
    Namer.set_name_fields(create_params)

    group = super(create_params)
    group.memberships.build(**initial_member)
    group
  end

  def to_disable
    [ user_group ] |
      user_group.projects |
      user_group.collections |
      user_group.memberships
  end

  def resource_name
    "user_group"
  end

  def link_header(resource)
    api_group_url(resource)
  end

  def initial_member
    {
     user: api_user.user,
     state: :active,
     roles: ["group_admin"]
    }
  end
end

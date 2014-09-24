class Api::V1::GroupsController < Api::ApiController
  include JsonApiController

  before_filter :require_login, only: [:create, :update, :destroy]
  doorkeeper_for :index, :create, :show, scopes: [:public]
  doorkeeper_for :update, :destroy, scopes: [:group]
  access_control_for :update, :create, :destroy
  
  alias_method :user_group, :controlled_resource

  resource_actions :show, :index, :update, :deactivate, :create

  allowed_params :create, :name, :display_name, links: [ :users ]
  allowed_params :update, :display_name
  
  private

  def create_resource(create_params)
    create_params[:display_name] ||= create_params[:name]

    group = super(create_params)
    group.build_owner_name(name: group.name, resource: group)
    group.memberships.build(**initial_member)
    group
  end

  def to_disable
    [ user_group ] |
      user_group.projects |
      user_group.collections |
      user_group.memberships
  end

  def update_relation(relation, value, replace=false)
    if relation == :users
      new_items(relation, value).each do |user|
        user_group.memberships.build(user: user,
                                     state: :invited,
                                     roles: ["group_member"])
      end
    else
      super
    end
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

class Api::V1::GroupsController < Api::ApiController
  include Recents
  include FilterByDisplayName

  doorkeeper_for :create, :update, :destroy, scopes: [:group]
  resource_actions :show, :index, :update, :deactivate, :create
  schema_type :strong_params

  alias_method :user_group, :controlled_resource

  allowed_params :create, :name, :display_name, links: [ users: [] ]
  allowed_params :update, :name, :display_name

  def destroy_links
    controlled_resources.first.memberships
      .where(user_id: params[:link_ids].split(',').map(&:to_i))
      .update_all(state: Membership.states[:inactive])
    deleted_resource_response
  end

  private

  def _resource_ids
    ids = if params.has_key?("group_id")
            params["group_id"]
          elsif params.has_key?(:id)
            params[:id]
          else
            ''
          end.split(',')

    ids.length < 2 ? ids.first : ids
  end

  def build_resource_for_create(create_params)
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

class Api::V1::UserGroupsController < Api::ApiController
  include JsonApiController::PunditPolicy
  include Recents
  include IndexSearch

  require_authentication :create, :update, :destroy, scopes: [:group]
  resource_actions :show, :index, :update, :deactivate, :create
  schema_type :strong_params

  alias_method :user_group, :controlled_resource

  allowed_params :create, :name, :display_name, :private, :stats_visibility, links: [users: []]
  allowed_params :update, :name, :private, :stats_visibility, :display_name

  search_by do |name, query|
    search_names = name.join(' ').downcase
    display_name_search = query.where('lower(display_name) = ?', search_names)

    if display_name_search.exists?
      display_name_search
    elsif search_names.present? && search_names.length >= 3
      query.full_search_display_name(search_names)
    else
      UserGroup.none
    end
  end

  def destroy_links
    controlled_resources.first.memberships
      .where(user_id: params[:link_ids].split(',').map(&:to_i))
      .update_all(state: Membership.states[:inactive])
    deleted_resource_response
  end

  private

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

  def initial_member
    {
     user: api_user.user,
     state: :active,
     roles: ["group_admin"]
    }
  end

  def context
    {current_user: api_user}
  end
end

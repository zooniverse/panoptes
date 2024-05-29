class UserGroupSerializer
  include Serialization::PanoptesRestpack
  include RecentLinkSerializer
  include CachedSerializer

  attributes :id, :name, :display_name, :classifications_count, :created_at, :updated_at, :type, :href, :join_token, :stats_visibility
  can_include :memberships, :users,
              projects: { param: "owner", value: "name" },
              collections: { param: "owner", value: "name" }

  preload :memberships, :users, :projects, :collections

  can_filter_by :name

  def type
    "user_groups"
  end

  private

  def include_join_token?
    return false unless current_user
    current_user.admin? || @model.has_admin?(current_user)
  end

  def current_user
    @context[:current_user]
  end
end

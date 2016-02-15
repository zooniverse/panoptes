class UserGroupSerializer
  include RestPack::Serializer
  include RecentLinkSerializer
  attributes :id, :name, :display_name, :classifications_count, :created_at, :updated_at, :type, :href, :join_token
  can_include :memberships, :users,
              projects: { param: "owner", value: "name" },
              collections: { param: "owner", value: "name" }

  can_filter_by :name

  def type
    "user_groups"
  end

  private

  def include_join_token?
    return false unless current_user
    @model.has_admin? current_user
  end

  def current_user
    @context[:current_user]
  end
end

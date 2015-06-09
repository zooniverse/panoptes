class UserGroupSerializer
  include RestPack::Serializer
  include RecentLinkSerializer
  include BlankTypeSerializer
  attributes :id, :display_name, :classifications_count, :created_at, :updated_at, :type,
    :slug
  can_include :memberships, :users,
              projects: { param: "owner", value: "slug" },
              collections: { param: "owner", value: "slug" }

  can_filter_by :display_name

  def type
    "user_groups"
  end

  def self.recents_base_url
    "groups"
  end
end

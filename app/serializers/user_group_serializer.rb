class UserGroupSerializer
  include RestPack::Serializer
  include RecentLinkSerializer
  attributes :id, :name, :display_name, :classifications_count, :created_at, :updated_at, :type, :href
  can_include :memberships, :users,
              projects: { param: "owner", value: "name" },
              collections: { param: "owner", value: "name" }

  can_filter_by :name

  def type
    "user_groups"
  end

  def self.recents_base_url
    "groups"
  end
end

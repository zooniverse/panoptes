class UserGroupSerializer
  include RestPack::Serializer
  attributes :id, :display_name, :classifications_count, :created_at, :updated_at, :type
  can_include :memberships, :users,
              projects: { param: "owner", value: "display_name" },
              collections: { param: "owner", value: "display_name" }

  can_filter_by :display_name

  def type
    "user_groups"
  end
end

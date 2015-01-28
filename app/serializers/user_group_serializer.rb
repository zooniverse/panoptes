class UserGroupSerializer
  include RestPack::Serializer
  attributes :id, :name, :display_name, :classifications_count, :created_at, :updated_at
  can_include :memberships, :users,
              projects: { param: "owner", value: "name" },
              collections: { param: "owner", value: "name" }

  can_filter_by :name
end

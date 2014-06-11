class UserGroupSerializer
  include RestPack::Serializer
  attributes :id, :name, :display_name, :classifications_count, :created_at, :updated_at
  can_include :memberships, :users, :projects, :collections
end

class UserSerializer
  include RestPack::Serializer
  attributes :id, :login, :display_name, :credited_name, :created_at, :updated_at
  can_include :projects, :collections, :classifications, :subjects
end

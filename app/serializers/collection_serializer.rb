class CollectionSerializer
  include RestPack::Serializer
  attributes :id, :name, :display_name, :created_at, :updated_at
  can_include :project, :owner
end

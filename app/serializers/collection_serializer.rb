class CollectionSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer
  include FilterHasMany

  attributes :id, :name, :display_name, :created_at, :updated_at
  can_include :project, :owner
  can_filter_by :display_name, :name
end

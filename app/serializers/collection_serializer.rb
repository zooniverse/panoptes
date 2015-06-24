class CollectionSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer
  include FilterHasMany

  attributes :id, :name, :display_name, :created_at, :updated_at,
    :slug, :href
  can_include :project, :owner, :collection_roles, :subjects
  can_filter_by :display_name, :slug
end

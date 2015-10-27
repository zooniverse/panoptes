class CollectionSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer
  include FilterHasMany
  include BelongsToManyLinks

  attributes :id, :name, :display_name, :created_at, :updated_at,
    :slug, :href, :favorite, :private
  can_include :projects, :owner, :collection_roles, :subjects
  can_filter_by :display_name, :slug, :favorite
end

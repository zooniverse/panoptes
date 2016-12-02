class CollectionSerializer
  include RestPack::Serializer
  include OwnerLinkSerializer
  include FilterHasMany
  include BelongsToManyLinks

  PRELOADS = [
    [ owner: { identity_membership: :user } ],
    :collection_roles,
    :subjects
  ].freeze

  attributes :id, :name, :display_name, :created_at, :updated_at,
    :slug, :href, :favorite, :private

  # Do not include the BelongsToMany :projects relation
  # as this can't be preloaded (custom AR relation)
  # Note: this won't allow ?include=projects side loading of the resource
  can_include :owner, :collection_roles, :subjects

  can_filter_by :display_name, :slug, :favorite

  # overridden belongs_to_many association to serialize the :projects links
  def self.btm_associations
    [ model_class.reflect_on_association(:projects) ]
  end

  def self.page(params = {}, scope = nil, context = {})
    scope = scope.preload(*PRELOADS)
    super(params, scope, context)
  end
end

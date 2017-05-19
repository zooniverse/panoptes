class CollectionSerializer
  include Serialization::PanoptesRestpack
  include FilterHasMany
  include OwnerLinkSerializer
  include BelongsToManyLinks
  include CachedSerializer

  attributes :id, :name, :display_name, :created_at, :updated_at,
    :slug, :href, :favorite, :private, :default_subject_src, :description

  # Do not include the BelongsToMany :projects relation
  # as this can't be preloaded (custom AR relation)
  # Note: this won't allow ?include=projects side loading of the resource
  can_include :owner, :collection_roles, :subjects

  can_filter_by :display_name, :slug, :favorite
  can_sort_by :display_name

  preload [ owner: { identity_membership: :user } ], :collection_roles, :subjects

  # overridden belongs_to_many association to serialize the :projects links
  def self.btm_associations
    [ model_class.reflect_on_association(:projects) ]
  end

  def default_subject_src
    if @model.default_subject
      @model.default_subject&.locations&.first&.url_for_format(:get)
    else
      @model.subjects.first&.locations&.first&.url_for_format(:get)
    end
  end
end

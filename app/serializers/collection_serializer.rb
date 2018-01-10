class CollectionSerializer
  include Serialization::PanoptesRestpack
  include FilterHasMany
  include OwnerLinkSerializer
  include BelongsToManyLinks # TODO: After PR #2563, remove this line
  include CachedSerializer

  attributes :id, :name, :display_name, :created_at, :updated_at,
    :slug, :href, :favorite, :private, :default_subject_src, :description

  # Do not include the BelongsToMany :projects relation
  # as this can't be preloaded (custom AR relation)
  # Note: this won't allow ?include=projects side loading of the resource
  # TODO: After PR #2563, remove comment and rename "habtm_projects" in the can_include list
  can_include :owner, :collection_roles, :subjects, :habtm_projects

  can_filter_by :display_name, :slug, :favorite
  can_sort_by :display_name

  preload [ owner: { identity_membership: :user } ],
    :collection_roles,
    :subjects,
    default_subject: :locations

  # TODO: After PR #2563, remove this method
  def self.btm_associations
    [ model_class.reflect_on_association(:projects) ]
  end

  def default_subject_src
    media_locations =
      if default_subject = @model.default_subject
        default_subject.ordered_locations
      elsif first_subject = @model.subjects.first
        first_subject.ordered_locations
      else
        []
      end

    media_locations.first&.get_url
  end
end

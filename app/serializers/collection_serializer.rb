class CollectionSerializer
  include Serialization::PanoptesRestpack
  include FilterHasMany
  include OwnerLinkSerializer
  include CachedSerializer

  attributes :id, :name, :display_name, :created_at, :updated_at,
    :slug, :href, :favorite, :private, :default_subject_src, :description

  can_include :owner, :collection_roles, :subjects, :projects

  can_filter_by :display_name, :slug, :favorite
  can_sort_by :display_name

  preload [ owner: { identity_membership: :user } ],
    :collection_roles,
    :subjects,
    default_subject: :locations

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

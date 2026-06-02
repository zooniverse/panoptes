class CollectionSerializer
  include Serialization::PanoptesRestpack
  include FilterHasMany
  include OwnerLinkSerializer
  include CachedSerializer

  attributes :id, :name, :display_name, :created_at, :updated_at,
    :slug, :href, :favorite, :private, :default_subject_src, :description

  can_include :owner, :collection_roles, :subjects, :projects

  can_filter_by :display_name, :slug, :favorite, :min_subjects
  can_sort_by :display_name


  preload [ owner: { identity_membership: :user } ],
    :collection_roles,
    :subjects,
    :projects,
    default_subject: :locations

  def self.page(params={}, scope=nil, context={})
    page_with_options CustomScopeFilterOptions.new(self, params, scope, context)
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

  private

  class CustomScopeFilterOptions < RestPack::Serializer::Options
    CUSTOM_SCOPE_FILTERS = %i[min_subjects].freeze

    def scope_with_filters
      filtered_scope = apply_standard_filters
      return filtered_scope unless @filters.key?(:min_subjects)

      filter_min_subjects_count(filtered_scope)
    end

    private

    def apply_standard_filters
      scope_filter = {}
      non_custom_filters = @filters.except(*CUSTOM_SCOPE_FILTERS)
      non_custom_filters.each_key do |filter|
        value = query_to_array(@filters[filter])
        scope_filter[filter] = value
      end
      @scope.where(scope_filter)
    end

    def filter_min_subjects_count(scope)
      min_subjects_count = @filters[:min_subjects]
      scope.joins(:collections_subjects).group(:id).having("COUNT(collections_subjects.id) >= ?", min_subjects_count)
    end
  end
end

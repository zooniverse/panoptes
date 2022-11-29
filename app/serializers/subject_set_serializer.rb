class SubjectSetSerializer
  include Serialization::PanoptesRestpack
  include FilterHasMany
  include CachedSerializer

  attributes :id, :display_name, :set_member_subjects_count, :metadata,
             :created_at, :updated_at, :href, :completeness

  can_include :project, :workflows
  can_sort_by :display_name, :id
  can_filter_by :display_name

  preload :workflows
end

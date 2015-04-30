class SubjectSetSerializer
  include RestPack::Serializer
  include FilterHasMany

  attributes :id, :display_name, :set_member_subjects_count, :metadata,
    :created_at, :updated_at
  can_include :project, :workflows

  can_filter_by :display_name
end

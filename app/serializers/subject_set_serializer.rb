class SubjectSetSerializer
  include RestPack::Serializer
  attributes :id, :display_name, :set_member_subjects_count, :retirement,
             :metadata, :created_at, :updated_at, :retired_set_member_subjects_count
  can_include :project, :workflows

  can_filter_by :display_name
end

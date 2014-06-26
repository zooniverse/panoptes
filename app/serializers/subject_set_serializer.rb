class SubjectSetSerializer
  include RestPack::Serializer
  attributes :id, :name, :set_member_subjects_count, :created_at, :updated_at
  can_include :project, :workflows
end

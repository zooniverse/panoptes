class SubjectSetSerializer
  include RestPack::Serializer
  attributes :id, :subject_count, :created_at, :updated_at
  can_include :project, :workflows
end

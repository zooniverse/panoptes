class SetMemberSubjectSerializer
  include RestPack::Serializer

  attributes :id, :created_at, :updated_at, :priority, :href
  can_include :subject_set, :subject, :retired_workflows
end

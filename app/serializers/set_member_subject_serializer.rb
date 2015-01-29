class SetMemberSubjectSerializer
  include RestPack::Serializer
  attributes :id, :created_at, :updated_at, :state, :priority
  can_include :subject_set, :subject
end

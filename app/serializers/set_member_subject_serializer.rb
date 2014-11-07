class SetMemberSubjectSerializer
  include RestPack::Serializer
  attributes :id, :created_at, :updated_at, :classifications_count, :state, :priority
  can_include :subject_set, :subject
end

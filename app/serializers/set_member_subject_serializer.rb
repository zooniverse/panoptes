class SetMemberSubjectSerializer
  include RestPack::Serializer
  include BelongsToManyLinks
 
  attributes :id, :created_at, :updated_at, :state, :priority
  can_include :subject_set, :subject, :retired_workflows
end

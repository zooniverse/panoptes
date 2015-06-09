class SubjectQueueSerializer
  include RestPack::Serializer
  include BelongsToManyLinks
  include BlankTypeSerializer

  attributes :id
  can_include :user, :workflow, :subject_set, :set_member_subjects
end

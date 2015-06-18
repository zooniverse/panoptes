class SubjectQueueSerializer
  include RestPack::Serializer
  include BelongsToManyLinks

  attributes :id, :href
  can_include :user, :workflow, :subject_set, :set_member_subjects
end

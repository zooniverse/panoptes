class UserSubjectQueueSerializer
  include RestPack::Serializer
  attribute :id
  can_include :user, :workflow#, :set_member_subjects

  def self.key
    "subject_queues"
  end
end

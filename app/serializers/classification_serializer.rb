class ClassificationSerializer
  include RestPack::Serializer
  attributes :id, :annotations, :created_at
  can_include :project, :set_member_subject, :user, :user_group
end

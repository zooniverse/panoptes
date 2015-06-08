class MembershipSerializer
  include RestPack::Serializer
  include BlankTypeSerializer
  attributes :id, :state
  can_include :user, :user_group
end

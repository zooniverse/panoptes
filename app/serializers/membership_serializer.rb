class MembershipSerializer
  include RestPack::Serializer
  attributes :id, :state
  can_include :user, :user_group
end

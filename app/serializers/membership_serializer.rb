class MembershipSerializer
  include RestPack::Serializer
  attributes :id, :state, :href
  can_include :user, :user_group
end

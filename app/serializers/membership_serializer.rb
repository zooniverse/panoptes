class MembershipSerializer
  include RestPack::Serializer
  include CachedSerializer

  attributes :id, :state, :href
  can_include :user, :user_group
end

class MembershipSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :state, :href
  can_include :user, :user_group
end

class UserCollectionPreferenceSerializer
  include RestPack::Serializer
  include CachedSerializer

  attributes :id, :preferences, :href
  can_include :user, :collection

  def self.key
    "collection_preferences"
  end
end

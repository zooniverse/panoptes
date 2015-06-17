class UserCollectionPreferenceSerializer
  include RestPack::Serializer
  attributes :id, :preferences, :href
  can_include :user, :collection

  def self.key
    "collection_preferences"
  end
end

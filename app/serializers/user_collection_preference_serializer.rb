class UserCollectionPreferenceSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :preferences, :href
  can_include :user, :collection

  def self.key
    "collection_preferences"
  end
end

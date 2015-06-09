class UserCollectionPreferenceSerializer
  include RestPack::Serializer
  include BlankTypeSerializer
  attributes :id, :preferences
  can_include :user, :collection

  def self.key
    "collection_preferences"
  end
end

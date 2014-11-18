class UserCollectionRoleSerializer
  include RestPack::Serializer
  attributes :id, :roles
  can_include :user, :collection

  def self.key
    'collection_roles'
  end

  def self.model_class
    UserCollectionPreference
  end
end

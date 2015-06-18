class CollectionRoleSerializer
  include ACLSerializer

  attributes :id, :roles, :href
  can_include :user_group, :resource

  def self.key
    "collection_roles"
  end

  def self.resource_type
    "collection"
  end
end

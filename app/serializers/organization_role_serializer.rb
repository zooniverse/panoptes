class OrganizationRoleSerializer
  include AclSerializer

  attributes :id, :roles, :href
  can_include :user_group, :resource

  def self.key
    "organization_roles"
  end

  def self.resource_type
    "organization"
  end
end

class OrganizationRoleSerializer
  include AclSerializer

  attributes :id, :roles, :href
  can_include :user_group, :resource

  def self.key
    :organization_roles
  end

  def self.page_with_options(options)
    options.scope = options.scope.where(resource_type: resource_type.classify)
    super
  end

  def self.resource_type
    "organization"
  end
end

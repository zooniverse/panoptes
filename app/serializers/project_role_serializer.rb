class ProjectRoleSerializer
  include ACLSerializer

  attributes :id, :roles, :href
  can_include :user_group, :resource

  def self.key
    "project_roles"
  end

  def self.resource_type
    "project"
  end
end

class WorkflowRoleSerializer
  include ACLSerializer

  attributes :id, :roles, :href
  can_include :user_group, :resource

  def self.key
    'workflow_roles'
  end

  def self.resource_type
    'workflow'
  end
end

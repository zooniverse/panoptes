class UserProjectRoleSerializer
  include RestPack::Serializer
  attributes :id, :roles
  can_include :user, :project

  def self.key
    'project_roles'
  end

  def self.model_class
    UserProjectPreference
  end
end

class AccessControlListPolicy < ApplicationPolicy
  def linkable_organizations
    policy_for(Organization).scope_for(:update)
  end

  def linkable_projects
    policy_for(Project).scope_for(:update)
  end

  def linkable_collections
    policy_for(Collection).scope_for(:update)
  end
end

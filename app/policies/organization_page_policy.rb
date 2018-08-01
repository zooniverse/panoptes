class OrganizationPagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(Organization).scope_for(action)
      scope.where(organization_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, :update, :destroy, :translate, :versions, :version, with: Scope

  def linkable_organizations
    policy_for(Organization).scope_for(:update)
  end
end

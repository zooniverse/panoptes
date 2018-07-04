class OrganizationPagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(Organization).scope_for(action)
      scope.where(organization_id: parent_scope.select(:id))
    end
  end

  class TranslateScope < Scope
    def resolve(action)
      super(:translate)
    end
  end

  scope :index, :show, with: Scope
  scope :update, :destroy, :update_links, :destroy_links, :versions, :version, with: TranslateScope
end

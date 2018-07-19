class OrganizationContentPolicy < ApplicationPolicy
  class ReadScope < Scope
    def resolve(action)
      parent_scope = policy_for(Organization).scope_for(action)
      scope.where(organization_id: parent_scope.select(:id))
    end
  end

  class WriteScope < Scope
    def resolve(action)
      parent_scope = policy_for(Organization).scope_for(:translate)
      scope.where(organization_id: parent_scope.select(:id))
        .joins(:organization)
        .where.not("\"#{Organization.table_name}\".\"primary_language\" = \"#{model.table_name}\".\"language\"")
    end
  end

  scope :index, :show, :versions, :version, with: ReadScope
  scope :update, :destroy, with: WriteScope

  def linkable_organizations
    policy_for(Organization).scope_for(:translate)
  end
end

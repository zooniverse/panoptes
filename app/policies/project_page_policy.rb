class ProjectPagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(Project).scope_for(action)
      scope.where(project_id: parent_scope.select(:id))
    end
  end

  class TranslateScope < Scope
    def resolve(_action)
      parent_scope = policy_for(Project).scope_for(:translate)
      scope.where(project_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, with: Scope
  scope :update, :destroy, :translate,
        :update_links, :destroy_links,
        :versions, :version, with: TranslateScope

  def linkable_projects
    policy_for(Project).scope_for(:update)
  end
end

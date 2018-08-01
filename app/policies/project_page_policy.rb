class ProjectPagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(Project).scope_for(action)
      scope.where(project_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, :update, :destroy, :translate, :versions, :version, with: Scope

  def linkable_projects
    policy_for(Project).scope_for(:update)
  end
end

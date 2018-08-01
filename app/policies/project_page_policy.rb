class ProjectPagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(Project).scope_for(action)
      scope.where(project_id: parent_scope.select(:id))
    end
  end

  # TODO: look into removing :update_links, :destroy_links as these route actions don't exist for this resource
  scope :index, :show, :update, :destroy, :translate, :versions,
        :version, :update_links, :destroy_links, with: Scope

  def linkable_projects
    policy_for(Project).scope_for(:update)
  end
end

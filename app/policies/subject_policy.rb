class SubjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(Project).scope_for(action)
      scope.where(project_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, :update, :destroy, :update_links, :destroy_links, :versions, :version, with: Scope

  def linkable_projects
    policy_for(Project).scope_for(:update)
  end

  def linkable_subject_sets
    policy_for(SubjectSet).scope_for(:update)
  end
end

class SubjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(Project).scope_for(action)
      scope.where(project_id: parent_scope.select(:id))
    end
  end

  # use the project show parent scope to lookup
  # the authorized context for this user.
  # i.e. if they can see a project they can access it's subjects
  class AdjacentScope < Scope
    def resolve(action)
      parent_scope = policy_for(Project).scope_for(:show)
      scope.where(project_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, :update, :destroy, :versions, :version, with: Scope
  scope :adjacent, with: AdjacentScope

  def linkable_projects
    policy_for(Project).scope_for(:update)
  end

  def linkable_subject_sets
    policy_for(SubjectSet).scope_for(:update)
  end
end

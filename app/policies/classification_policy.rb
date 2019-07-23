class ClassificationPolicy < ApplicationPolicy
  class CompleteScope < Scope
    def resolve(action)
      return scope.complete if user.is_admin?

      scope.complete.merge(scope.created_by(user))
    end
  end

  class ShowScope < Scope
    def resolve(action)
      return scope.all if user.is_admin?

      scope.created_by(user)
    end
  end

  class ProjectScope < Scope
    def resolve(action)
      return scope.all if user.is_admin?

      projects = policy_for(Project).scope_for(:update)
      scope.where(project_id: projects.select(:id))
    end
  end

  class IncompleteScope < Scope
    def resolve(action)
      return scope.incomplete if user.is_admin?

      scope.incomplete_for_user(user)
    end
  end

  scope :index, with: CompleteScope
  scope :show, with: ShowScope
  scope :project, with: ProjectScope
  scope :update, :destroy, :incomplete, with: IncompleteScope

  def linkable_projects
    policy_for(Project).scope_for(:show)
  end

  def linkable_workflows
    policy_for(Workflow).scope_for(:show)
  end

  def linkable_subjects
    policy_for(Subject).scope_for(:show)
  end
end

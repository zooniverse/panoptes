class ClassificationPolicy < ApplicationPolicy
  class CompleteScope < Scope
    include FilterForbiddenProjects

    def resolve(action)
      return filter_forbidden_projects(scope.complete) if user.is_admin?
      filter_forbidden_projects(scope.complete.merge(scope.created_by(user)))
    end
  end

  class ShowScope < Scope
    include FilterForbiddenProjects

    def resolve(action)
      return filter_forbidden_projects(scope.all) if user.is_admin?
      filter_forbidden_projects(scope.created_by(user))
    end
  end

  class ProjectScope < Scope
    include FilterForbiddenProjects

    def resolve(action)
      return filter_forbidden_projects(scope.all) if user.is_admin?

      projects = policy_for(Project).scope_for(:update)
      filter_forbidden_projects(scope.where(project_id: projects.select(:id)))
    end
  end

  class IncompleteScope < Scope
    include FilterForbiddenProjects

    def resolve(action)
      return filter_forbidden_projects(scope.incomplete) if user.is_admin?
      filter_forbidden_projects(scope.incomplete_for_user(user))
    end
  end

  scope :index, with: CompleteScope
  scope :show, with: ShowScope
  scope :project, with: ProjectScope
  scope :update, :destroy, :incomplete, with: IncompleteScope
end

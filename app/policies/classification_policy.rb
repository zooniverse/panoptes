class ClassificationPolicy < ApplicationPolicy
  class CompleteScope < Scope
    def resolve(action)
      if user.is_admin?
        FilterByProjectId.whitelist_exportable_projects(scope.complete)
      else
        FilterByProjectId.whitelist_exportable_projects(
          scope.complete.merge(scope.created_by(user))
        )
      end
    end
  end

  class ShowScope < Scope
    def resolve(action)
      if user.is_admin?
        FilterByProjectId.whitelist_exportable_projects(scope.all)
      else
        FilterByProjectId.whitelist_exportable_projects(scope.created_by(user))
      end
    end
  end

  class ProjectScope < Scope
    def resolve(action)
      if user.is_admin?
        FilterByProjectId.whitelist_exportable_projects(scope.all)
      else
        projects = policy_for(Project).scope_for(:update)
        FilterByProjectId.whitelist_exportable_projects(
          scope.where(project_id: projects.select(:id))
        )
      end
    end
  end

  class IncompleteScope < Scope
    def resolve(action)
      if user.is_admin?
        FilterByProjectId.whitelist_exportable_projects(scope.incomplete)
      else
        FilterByProjectId.whitelist_exportable_projects(
          scope.incomplete_for_user(user)
        )
      end
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

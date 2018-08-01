class TutorialPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(Project).scope_for(action)
      scope.where(project_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, :update, :destroy, :translate, with: Scope

  def linkable_projects
    policy_for(Project).scope_for(:update)
  end

  def linkable_workflows
    project_workflows = record.project.workflows
    WorkflowPolicy::Scope.new(user, project_workflows).resolve(:update)
  end
end

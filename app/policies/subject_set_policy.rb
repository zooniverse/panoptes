class SubjectSetPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(Project).scope_for(action)
      scope.where(project_id: parent_scope.select(:id))
    end
  end

  scope *%i[index show update destroy create_classifications_export update_links destroy_links], with: Scope

  def linkable_projects
    policy_for(Project).scope_for(:update)
  end

  def linkable_workflows
    project_workflows = record.project.workflows
    WorkflowPolicy::Scope.new(user, project_workflows).resolve(:update)
  end

  def linkable_subjects
    policy_for(Subject).scope_for(:show)
  end
end

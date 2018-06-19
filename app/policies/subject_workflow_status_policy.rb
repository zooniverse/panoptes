class SubjectWorkflowStatusPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = Workflow.scope_for(action, user)
      scope.where(workflow_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, with: Scope
end

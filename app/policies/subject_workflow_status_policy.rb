class SubjectWorkflowStatusPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(Workflow).scope_for(action)
      scope.where(workflow_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, with: Scope
end

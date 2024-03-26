class AggregationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(Project).scope_for(:update)
      scope.where(workflow_id: parent_scope.select(:workflow_id))
    end
  end

  scope :index, :show, :update, :destroy, with: Scope

  def linkable_workflows
    policy_for(Workflow).scope_for(:update)
  end
end

# frozen_string_literal: true

class AggregationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      parent_scope = policy_for(Workflow).scope_for(:update)
      scope.where(workflow_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, :create, :update, :destroy, with: Scope

  def linkable_workflows
    policy_for(Workflow).scope_for(:update)
  end

  def linkable_projects
    policy_for(Project).scope_for(:update)
  end

  def linkable_users
    policy_for(User).scope_for(:update)
  end
end

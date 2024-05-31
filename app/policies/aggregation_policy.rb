class AggregationPolicy < ApplicationPolicy
  class ReadScope < Scope
    # Short circuiting scopes for private aggrevations before they get removed next PR
    def resolve(action)
      parent_scope = policy_for(Workflow).scope_for(action)
      scope.where(workflow_id: parent_scope.select(:id))
    end
  end

  class WriteScope < Scope
    def resolve(action)
      parent_scope = policy_for(Workflow).scope_for(action)
      scope.where(workflow_id: parent_scope.select(:id))
    end
  end

  scope :index, :show, with: ReadScope
  scope :update, :destroy, :versions, :version, with: WriteScope

  def linkable_subjects
    policy_for(Subject).scope_for(:show)
  end

  def linkable_workflows
    policy_for(Workflow).scope_for(:update)
  end
end

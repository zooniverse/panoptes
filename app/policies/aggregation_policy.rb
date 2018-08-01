class AggregationPolicy < ApplicationPolicy
  class ReadScope < Scope
    # Allow access to public aggregations
    def resolve(action)
      updatable_parents = policy_for(Workflow).scope_for(:update)
      updatable_scope = scope.joins(:workflow).merge(updatable_parents)

      scope.joins(:workflow)
        .where("workflows.aggregation ->> 'public' = 'true'")
        .union(updatable_scope)
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

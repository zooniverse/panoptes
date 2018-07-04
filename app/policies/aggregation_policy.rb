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
  scope :update, :destroy, :update_links, :destroy_links, :versions, :version, with: WriteScope
end

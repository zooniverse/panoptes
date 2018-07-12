class WorkflowContentPolicy < ApplicationPolicy
  class ReadScope < Scope
    def resolve(action)
      parent_scope = policy_for(Workflow).scope_for(action)
      scope.where(workflow_id: parent_scope.select(:id))
    end
  end

  class WriteScope < Scope
    def resolve(action)
      parent_scope = policy_for(Workflow).scope_for(:translate)
      scope.where(workflow_id: parent_scope.select(:id))
        .joins(:workflow)
        .where.not("\"#{Workflow.table_name}\".\"primary_language\" = \"#{model.table_name}\".\"language\"")
    end
  end

  scope :index, :show, :versions, :version, with: ReadScope
  scope :update, :destroy, with: WriteScope
end

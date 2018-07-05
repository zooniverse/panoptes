class ProjectContentPolicy < ApplicationPolicy
  class ReadScope < Scope
    def resolve(action)
      parent_scope = policy_for(Project).scope_for(action)
      scope.where(project_id: parent_scope.select(:id))
    end
  end

  class WriteScope < Scope
    def resolve(action)
      parent_scope = policy_for(Project).scope_for(:translate)
      scope.where(project_id: parent_scope.select(:id))
        .joins(:project)
        .where.not("\"#{Project.table_name}\".\"primary_language\" = \"#{model.table_name}\".\"language\"")
    end
  end

  scope :index, :show, :versions, :version, with: ReadScope
  scope :update, :destroy, with: WriteScope
end

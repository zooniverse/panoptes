class UserProjectPreferenceVisibilityQuery < VisibilityQuery
  private

  def queries
    [where_user, where_project]
  end

  def all_bind_values
    project_scope.bind_values
  end

  def union_table
    Arel::Table.new(:user_project_preferences)
  end

  def project_scope
    @project_scope ||= Project.scope_for(:update, actor).select(:id)
  end

  def where_user
    @where_user ||= parent.where(arel_table[:user_id].eq(actor.id))
  end

  def where_project
    @where_project ||= parent.where(arel_table[:project_id].in(project_scope.arel))
  end
end

class ClassificationVisibilityQuery < VisibilityQuery
  private

  def queries
    [where_user, where_project, where_group]
  end

  def all_bind_values
    project_scope.bind_values | group_scope.bind_values
  end

  def project_scope
    @project_scope ||= Project.scope_for(:update, actor).select(:id)
  end

  def group_scope
    @group_query ||= actor.owner.user_groups.select(:id)
  end


  def where_user
    @where_user ||= parent.where(arel_table[:user_id].eq(actor.id))
  end

  def where_project
    @where_project ||= parent.where(arel_table[:project_id].in(project_scope.arel))
  end

  def where_group
    @where_group ||= parent.where(arel_table[:user_group_id].in(group_scope.arel))
  end

  def union_table
    Arel::Table.new(:classifications)
  end
end

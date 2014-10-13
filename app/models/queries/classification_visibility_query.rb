class ClassificationVisibilityQuery < VisibilityQuery
  private

  def queries
    [where_user, where_project, where_group]
  end
  
  def arel_table
    @parent.arel_table
  end

  def all_bind_values
    where_user.bind_values | where_project.bind_values | where_group.bind_values
  end
  
  def where_user
    @where_user ||= @parent.where(user_id: actor.id)
  end
  
  def where_project
    @where_project ||= @parent.where(project_id: project_scope)
  end

  def where_group
    @where_group ||= @parent.where(user_group_id: group_scope)
  end

  def union_table
    Arel::Table.new(:classifications)
  end
end

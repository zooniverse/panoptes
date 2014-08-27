class ClassificationVisibilityQuery
  attr_reader :actor
  
  def initialize(actor, parent)
    @actor, @parent = actor, parent
  end
  
  def build(as_admin)
    return @parent.all if actor.is_admin? && as_admin
    query = @parent.where(where_user
                          .or(where_project)
                          .or(where_group))
    rebind(query)
  end

  private

  def rebind(query)
    all_bind_values.reduce(query) { |query, value| query.bind(value) }
  end
  
  def arel_table
    @parent.arel_table
  end

  def all_bind_values
    project_scope.bind_values | group_scope.bind_values
  end
  
  def where_user
    arel_table[:user_id].eq(actor.id)
  end

  def project_scope
    @project_scope ||= Project.scope_for(:update, actor).select(:id)
  end

  def group_scope
    @group_query ||= actor.owner.user_groups.select(:id)
  end

  def where_project
    arel_table[:project_id].in(project_scope.arel)
  end

  def where_group
    arel_table[:user_group_id].in(group_scope.arel)
  end
end

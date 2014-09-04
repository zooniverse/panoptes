class ClassificationVisibilityQuery
  attr_reader :actor
  
  def initialize(actor, parent)
    @actor, @parent = actor, parent
  end
  
  def build(as_admin)
    return @parent.all if actor.is_admin? && as_admin

    query = Arel::Nodes::UnionAll.new(where_project.arel.ast,
                                      where_group.arel.ast)
    query = Arel::Nodes::UnionAll.new(where_user.arel.ast,
                                      query)
    query = Arel::Nodes::As.new(query, union_table) 

    query = @parent.from(query)

    rebind(query)
  end

  private

  def rebind(query)
    reindex_binds(query)
    all_bind_values.reduce(query) { |query, value| query.bind(value) }
  end

  def reindex_binds(query)
    query.arel.ast.grep(Arel::Nodes::BindParam).each_with_index do |bp, i|
      bv = all_bind_values[i]
      bp.replace(@parent.connection.substitute_at(bv, i))
    end
  end
  
  def arel_table
    @parent.arel_table
  end

  def all_bind_values
    project_scope.bind_values | group_scope.bind_values
  end
  
  def where_user
    @parent.where(arel_table[:user_id].eq(actor.id))
  end

  def project_scope
    @project_scope ||= Project.scope_for(:update, actor).select(:id)
  end

  def group_scope
    @group_query ||= actor.owner.user_groups.select(:id)
  end

  def where_project
    @parent.where(arel_table[:project_id].in(project_scope.arel))
  end

  def where_group
    @parent.where(arel_table[:user_group_id].in(group_scope.arel))
  end

  def union_table
    Arel::Table.new(:classifications)
  end
end

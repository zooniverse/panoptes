class ClassificationVisibilityQuery
  attr_reader :actor
  
  def initialize(actor, parent)
    @actor, @parent = actor, parent
  end
  
  def build(as_admin)
    return @parent.all if actor.is_admin? && as_admin

    query = query_asts.reduce do |query, ast|
      Arel::Nodes::UnionAll.new(query, ast)
    end
    
    query = Arel::Nodes::As.new(query, union_table) 

    query = @parent.from(query)

    rebind(query)
  end

  private

  def rebind(query)
    reindex_binds
    all_bind_values.reduce(query) { |query, bind_value| query.bind(bind_value) }
  end

  def query_asts
    [where_user.arel.ast, where_project.arel.ast, where_group.arel.ast]
  end

  def reindex_binds
    bind_index = 0
    query_asts.each do |ast|
      ast.grep(Arel::Nodes::BindParam).each do |bp|
        bv = all_bind_values[bind_index]
        bp.replace(@parent.connection.substitute_at(bv, bind_index))
        bind_index += 1
      end
    end
  end
  
  def arel_table
    @parent.arel_table
  end

  def all_bind_values
    project_scope.bind_values | group_scope.bind_values
  end
  
  def where_user
    @where_user ||= @parent.where(arel_table[:user_id].eq(actor.id))
  end

  def project_scope
    @project_scope ||= Project.scope_for(:update, actor).select(:id)
  end

  def group_scope
    @group_query ||= actor.owner.user_groups.select(:id)
  end

  def where_project
    @where_project ||= @parent.where(arel_table[:project_id].in(project_scope.arel))
  end

  def where_group
    @where_group ||= @parent.where(arel_table[:user_group_id].in(group_scope.arel))
  end

  def union_table
    Arel::Table.new(:classifications)
  end
end

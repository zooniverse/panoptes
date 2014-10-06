module UnionQueryBuilder
  def build
    query = query_asts.reduce do |query, ast|
      Arel::Nodes::UnionAll.new(query, ast)
    end
    
    query = Arel::Nodes::As.new(query, union_table) 
    query = parent.from(query)

    rebind(query)
  end

  private

  def query_asts
    @query_asts ||= queries.map(&:arel).map(&:ast)
  end
  
  def rebind(query)
    reindex_binds
    all_bind_values.reduce(query) do |query, bind_value|
      query.bind(bind_value)
    end
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
end

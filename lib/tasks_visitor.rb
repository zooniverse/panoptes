class TasksVisitor
  def visit(node, collector=nil, key=nil)
    if key
      method = :"visit_#{key}"
    else
      method = :visit_hash
    end

    send(method, node, collector)
  rescue NoMethodError => e
    send(:visit_hash, node, collector)
  end

  private

  def array_node(n, c)
    n.map { |sub_node| visit(sub_node, c) }
  end

  def noop(n,c)
    n
  end

  def visit_hash(n, c)
    n.each do |k, v|
      n[k] = visit(v, c, k)
    end
  end

  %w(tools answers).each do |key|
    alias :"visit_#{key}" :array_node
  end

  %w(type value type color required next).each do |key|
    alias :"visit_#{key}" :noop
  end
end

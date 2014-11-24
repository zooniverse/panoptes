class TasksVisitor
  def visit(node, path=[], key=nil)
    method = :"visit_#{key}"
    method = respond_to?(method, true) ? method : :visit_hash
    send(method, node, path)
  end

  private

  def array_node(n, path)
    n.each_with_index.map { |sub_node, i| visit(sub_node, path + [i]) }
  end

  def noop(n, p)
    n
  end

  def visit_hash(n, path)
    n.each do |k, v|
      n[k] = visit(v, path + [k], k)
    end
  end

  %w(tools answers).each do |key|
    alias :"visit_#{key}" :array_node
  end

  %w(type value type color required next).each do |key|
    alias :"visit_#{key}" :noop
  end
end

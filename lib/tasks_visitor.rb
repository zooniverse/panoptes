class TasksVisitor
  def visit(node, key=nil)
    method = :"visit_#{key}"
    method = respond_to?(method, true) ? method : :visit_hash
    send(method, node)
  end

  private

  def array_node(n)
    n.map { |sub_node| visit(sub_node) }
  end

  def noop(n)
    n
  end

  def visit_hash(n)
    n.each do |k, v|
      n[k] = visit(v, k)
    end
  end

  %w(tools answers).each do |key|
    alias :"visit_#{key}" :array_node
  end

  %w(type value type color required next).each do |key|
    alias :"visit_#{key}" :noop
  end
end

class TasksVisitor
  def visit(node, collector=nil)
    send("visit_#{ node.class.name.gsub('::', '_') }", node, collector)
  end

  private

  def visit_Array(n, c)
    n.map { |sub_node| visit(sub_node, c) }
  end

  def noop(n,c)
    n
  end

  alias :visit_Hash :noop
  alias :visit_Fixnum :noop
  alias :visit_String :noop
  alias :visit_TrueClass :noop
  alias :visit_FalseClass :noop
  alias :visit_NilClass :noop
end

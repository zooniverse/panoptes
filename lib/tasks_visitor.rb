class TasksVisitor
  def visit(node, path=[], key=nil)
    method = :"visit_#{key}"
    method = respond_to?(method, true) ? method : :"visit_#{node.class.to_s.gsub('::', '_')}"
    send(method, node, path)
  end

  private

  def visit_Array(n, path)
    n.each_with_index.map { |sub_node, i| visit(sub_node, path + [i]) }
  end

  def noop(n, p)
    n
  end

  def visit_Hash(n, path)
    n.each do |k, v|
      n[k] = visit(v, path + [k], k)
    end
  end

  alias :visit_ActiveSupport_HashWithIndifferentAccess :visit_Hash
  alias :visit_ActionController_Parameters :visit_Hash

  alias :visit_String :noop
  alias :visit_TrueClass :noop
  alias :visit_FalseClass :noop
  alias :visit_NilClass :noop
  alias :visit_Fixnum :noop
  alias :visit_Float :noop
end

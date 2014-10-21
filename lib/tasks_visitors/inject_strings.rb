module TasksVisitors
  class InjectStrings < TasksVisitor
    def initialize(strings)
      @strings = strings
    end
    
    private
    
    def visit_Hash(n, c)
      n.each do |k, v|
        n[k] = visit(v, c)
      end
    end

    def visit_TasksVisitors_TaskIndex(n, c)
      @strings[n.index]
    end
  end
end

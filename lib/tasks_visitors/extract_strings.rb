module TasksVisitors
  class ExtractStrings < TasksVisitor
    private
    
    def visit_Hash(n, c)
      n.each do |k, v|
        case k
        when :label, :question
          c << v
          n[k] = TaskIndex.new(c.length - 1)
        else
          visit(v, c)
        end
      end
    end
  end
end

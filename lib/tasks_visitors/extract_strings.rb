module TasksVisitors
  class ExtractStrings < TasksVisitor
    private
    def substitute_string(n, c)
      c << n
      c.length - 1
    end

    alias :visit_label :substitute_string
    alias :visit_question :substitute_string
  end
end

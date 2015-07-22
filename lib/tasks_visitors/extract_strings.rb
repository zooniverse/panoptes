module TasksVisitors
  class ExtractStrings < TasksVisitor
    def initialize(collector={})
      @collector = collector
    end

    def collector
      @collector
    end

    private

    def substitute_string(n, path)
      path = path.join(".")
      @collector[path] = n
      path
    end

    alias :visit_instruction :substitute_string
    alias :visit_label :substitute_string
    alias :visit_question :substitute_string
    alias :visit_help :substitute_string
  end
end

module TasksVisitors
  class ExtractStrings < TasksVisitor
    def initialize(collector=[])
      @collector = collector
    end

    def collector
      @collector
    end

    private
    def substitute_string(n)
      @collector << n
      @collector.length - 1
    end

    alias :visit_label :substitute_string
    alias :visit_question :substitute_string
  end
end

module TasksVisitors
  class InjectStrings < TasksVisitor
    def initialize(strings)
      @strings = strings
    end

    private

    def inject_string(n, path=nil)
      @strings[n] || n
    end

    alias :visit_instruction :inject_string
    alias :visit_question :inject_string
    alias :visit_label :inject_string
    alias :visit_help :inject_string
  end
end

module TasksVisitors
  class InjectStrings < TasksVisitor
    def initialize(strings)
      @strings = strings
    end

    private

    def inject_string(n, path=nil)
      @strings[n] || n
    end

    def inject_nested_string(n, path=nil)
      extracted_string_key = path.join(".")
      @strings[extracted_string_key] || n
    end

    alias :visit_instruction :inject_string
    alias :visit_question :inject_string
    alias :visit_label :inject_string
    alias :visit_help :inject_string
    alias :visit_description :inject_string
    alias :visit_confusions :inject_nested_string
  end
end

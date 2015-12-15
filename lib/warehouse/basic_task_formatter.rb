module Warehouse
  class BasicTaskFormatter
    COLUMNS = %i(task task_label task_type tool tool_label value value_label choice answers filters marking frame details)

    attr_reader :translations, :task_definition

    def initialize(task_definition: {}, translations: {})
      @task_definition = task_definition || {}
      @translations = translations
    end

    def format(annotation)
      COLUMNS.each_with_object({}) do |column, hash|
        hash[column] = public_send(column, annotation)
      end
    end

    def task(annotation)
      annotation["task"]
    end

    def task_label(annotation)
      translate(task_definition["question"] || task_definition["instruction"])
    end

    def task_type(annotation)
      task_definition["type"] || "unknown"
    end

    def tool(annotation)
      nil
    end

    def tool_label(annotation)
      nil
    end

    def value(annotation)
      annotation.to_json
    end

    def value_label(annotation)
      nil
    end

    def choice(annotation)
      nil
    end

    def answers(annotation)
      nil
    end

    def filters(annotation)
      nil
    end

    def marking(annotation)
      nil
    end

    def frame(annotation)
      nil
    end

    def details(annotation)
      nil
    end

    private

    def translate(string)
      @translations[string]
    end
  end
end

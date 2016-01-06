module Warehouse
  class SingleTaskFormatter < BasicTaskFormatter
    def value(annotation)
      annotation["value"]
    end

    def value_label(annotation)
      return unless annotation["value"].is_a?(Integer)
      return unless task_definition["answers"].present?

      selected_option = task_definition["answers"][annotation["value"]]
      translate(selected_option["label"])
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
  end
end

module Warehouse
  class DrawingTaskFormatter < BasicTaskFormatter
    def format(annotation)
      annotation["value"].map do |value|
        COLUMNS.each_with_object({}) do |column, hash|
          hash[column] = public_send(column, {"task" => annotation["task"], "value" => value})
        end
      end
    end

    def tool(annotation)
      annotation["value"]["tool"]
    end

    def tool_label(annotation)
      tool_idx = annotation["value"]["tool"]
      translate(task_definition["tools"][tool_idx]["label"])
    end

    def value(annotation)
      nil
    end

    def marking(annotation)
      x = annotation["value"]["x"].round(4)
      y = annotation["value"]["y"].round(4)

      "#{x},#{y}"
    end

    def frame(annotation)
      annotation["value"]["frame"]
    end

    def details(annotation)
      annotation["value"]["details"].to_json
    end
  end
end

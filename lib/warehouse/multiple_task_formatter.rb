module Warehouse
  class MultipleTaskFormatter < BasicTaskFormatter
    def format(annotation)
      formatter = SingleTaskFormatter.new(task_definition: task_definition, translations: translations)

      annotation["value"].map do |value|
        single_annotation = annotation.dup.tap { |i| i["value"] = value }
        formatter.format(single_annotation)
      end
    end
  end
end

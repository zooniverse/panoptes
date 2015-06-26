module Formatter
  module Csv
    class AnnotationForCsv
      attr_reader :classification, :annotation

      def initialize(classification, annotation)
        @classification = classification
        @annotation = annotation.dup
      end

      def to_h
        annotation.merge! "task_label" => task_label

        case task["type"]
        when "drawing"
          value_with_tool = (annotation["value"] || []).map do |drawn_item|
            drawn_item.merge "tool_label" => tool_label(drawn_item)
          end

          annotation.merge!("value" => value_with_tool)
        end

        annotation
      end

      private

      def task_label
        translate(task["question"] || task["instruction"])
      end

      def tool_label(drawn_item)
        tool = task["tools"] && task["tools"][drawn_item["tool"]]
        translate(tool["label"]) if tool
      end

      def translate(string)
        @translations ||= classification.workflow.primary_content.strings
        @translations[string]
      end

      def task
        @task ||= classification.workflow.tasks.find {|key, task| key == annotation["task"] }.try(:last) || {}
      end
    end
  end
end

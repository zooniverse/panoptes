module Formatter
  module Csv
    class AnnotationForCsv
      attr_reader :classification, :annotation

      def initialize(classification, annotation)
        @classification = classification
        @annotation = annotation.dup
      end

      def to_h
        case task["type"]
        when "drawing"
          value_with_tool = annotation["value"].map do |drawn_item|
            tool = task["tools"][drawn_item["tool"]]
            drawn_item.merge "tool_label" => translate(tool["label"])
          end

          annotation.merge("value" => value_with_tool)
        else
          annotation
        end
      end

      private

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

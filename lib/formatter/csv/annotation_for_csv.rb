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
        @translations ||= primary_content_at_version.strings
        @translations[string]
      end

      def primary_content_at_version
        model_at_version(classification.workflow.primary_content, 1)
      end

      def workflow_at_version
        model_at_version(classification.workflow, 0)
      end

      def model_at_version(version, vers_index)
        version_num = classification.workflow_version.split(".")[vers_index].to_i
        if old_vers = version.versions[version_num].try(:reify)
          version = old_vers
        end
        version
      end

      def task
        return @task if @task
        task_annotation = workflow_at_version.tasks.find do |key, task|
          key == annotation["task"]
        end
        @task = task_annotation.try(:last) || {}
      end
    end
  end
end

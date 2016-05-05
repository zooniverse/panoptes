module Formatter
  module Csv
    class AnnotationForCsv
      attr_reader :classification, :annotation, :cache

      def initialize(classification, annotation, cache)
        @classification = classification
        @annotation = annotation.dup.with_indifferent_access
        @cache = cache
      end

      def to_h
        send(task["type"])
      end

      private

      def drawing
        # annotation.merge! "task_label" => task_label
        # value_with_tool = (annotation["value"] || []).map do |drawn_item|
        #  drawn_item.merge "tool_label" => tool_label(drawn_item)
        # end
        # annotation.merge!("value" => value_with_tool)
      end

      def simple
        {}.tap do |new_annotation|
          new_annotation['task'] = annotation['task']
          new_annotation['task_label'] = task_label
          new_annotation['value'] = task['type'] == 'multiple' ? answer_labels : answer_label
        end
      end

      alias_method :single, :simple
      alias_method :multiple, :simple

      def combo
        # {}.tap do |new_annotation|
        #   annotation['value'].each do |subtask|
        #     binding.pry

            # anno = annotation_by_task(subtask).last
            # answer_string = anno['answers'][subtask['value']]['label']
            # new_annotation['value'] = translate(answer_string)
            # new_annotation['task_label'] = translate(anno['question'])
          # end
        # end
      end

      def task_label
        translate(task["question"] || task["instruction"])
      end

      def tool_label(drawn_item)
        tool = task["tools"] && task["tools"][drawn_item["tool"]]
        translate(tool["label"]) if tool
      end

      def answer_label
        answer_labels.first
      end

      def answer_labels
        Array.wrap(annotation["value"]).map do |answer_idx|
          answer_string = task["answers"][answer_idx]["label"]
          translate(answer_string)
        end
      end

      def translate(string)
        @translations ||= primary_content_at_version.strings
        @translations[string]
      end

      def primary_content_at_version
        cache.workflow_content_at_version(classification.workflow.primary_content.id, content_version)
      end

      def workflow_at_version
        cache.workflow_at_version(classification.workflow_id, workflow_version)
      end

      def workflow_version
        classification.workflow_version.split(".")[0].to_i
      end

      def content_version
        classification.workflow_version.split(".")[1].to_i
      end

      def annotation_by_task(subtask)
        workflow_at_version.tasks.find do |key, task|
          key == subtask['task']
        end
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

module Formatter
  module Csv
    class AnnotationForCsv
      attr_reader :classification, :annotation, :cache

      def initialize(classification, annotation, cache)
        @classification = classification
        @annotation = annotation.dup.with_indifferent_access
        @current = @annotation.dup
        @cache = cache
      end

      def to_h
        send(task["type"])
      end

      private

      def drawing
        {}.tap do |new_anno|
          new_anno['task_label'] = task_label
          value_with_tool = (@current["value"] || []).map do |drawn_item|
           drawn_item.merge "tool_label" => tool_label(drawn_item)
          end
          new_anno["value"] = value_with_tool
        end
      end

      def simple
        {}.tap do |new_anno|
          new_anno['task'] = @current['task']
          new_anno['task_label'] = task_label
          new_anno['value'] = task['type'] == 'multiple' ? answer_labels : answer_label
        end
      end

      alias_method :single, :simple
      alias_method :multiple, :simple

      def text
        {}.tap do |new_anno|
          new_anno['task'] = @current['task']
          new_anno['task_label'] = task_label
        end
      end

      def combo
        {}.tap do |new_anno|
          annotation['value'].each do |subtask|
            @current = subtask
            task_info = get_task_info(subtask)
            # tasktype = task_info['type']
            new_anno['task'] = send(task_info['type'])

            # anno = annotation_by_task(subtask).last
            # answer_string = anno['answers'][subtask['value']]['label']
            # new_annotation['value'] = translate(answer_string)
            # new_annotation['task_label'] = translate(anno['question'])
            binding.pry
          end
        end
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
        Array.wrap(@current["value"]).map do |answer_idx|
          # answer_string = task["answers"][answer_idx]["label"]
          answer_string = workflow_at_version.tasks[@current['task']]['answers'][answer_idx]['label']
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

      def get_task_info(subtask)
        workflow_at_version.tasks.find do |key, task|
         key == subtask["task"]
        end.try(:last) || {}
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

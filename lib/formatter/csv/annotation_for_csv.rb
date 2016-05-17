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
        case task['type']
        when "drawing"
          drawing
        when "single", "multiple"
          simple
        when "text"
          text
        when "combo"
          combo
        when "dropdown"
          dropdown
        else
         { error: "task cannot be exported" }
        end
      end

      private

      def drawing(task_info=task)
        {}.tap do |new_anno|
          new_anno['task'] = @current['task']
          new_anno['task_label'] = task_label(task_info)
          value_with_tool = (@current["value"] || []).map do |drawn_item|
           drawn_item.merge "tool_label" => tool_label(task_info, drawn_item)
          end
          new_anno["value"] = value_with_tool
        end
      end

      def simple(task_info=task)
        {}.tap do |new_anno|
          new_anno['task'] = @current['task']
          new_anno['task_label'] = task_label(task_info)
          new_anno['value'] = task['type'] == 'multiple' ? answer_labels : answer_label
        end
      end

      def text(task_info=task)
        {}.tap do |new_anno|
          new_anno['task'] = @current['task']
          new_anno['value'] = @current['value']
          new_anno['task_label'] = task_label(task_info)
        end
      end

      def combo
        {}.tap do |new_anno|
          new_anno['task'] = annotation['task']
          new_anno['task_label'] = nil
          new_anno['value'] ||= []
          annotation['value'].each do |subtask|
            @current = subtask
            task_info = get_task_info(subtask)
            new_anno['value'].push send(task_info['type'], task_info)
          end
        end
      end

      def dropdown
        {}.tap do |new_anno|
          new_anno['task'] = @current['task']
          new_anno['value'] = []
          task['selects'].each_with_index do |selects, index|
            new_anno['value'].push dropdown_process_selects(selects, index)
          end
        end
      end

      def dropdown_process_selects(selects, index)
        {}.tap do |drop_anno|
          drop_anno['select_label'] = selects['title']
          drop_anno['option'] = selects['allowCreate']
          selects['options'].each do |key, options|
            dropdown_process_options(options, index, drop_anno)
          end
        end
      end

      def dropdown_process_options(options, index, drop_anno)
        options.each do |opt|
          if opt['value'] == @current['value'][index]['value']
            drop_anno['value'], drop_anno['label'] = dropdown_label(opt, index)
          end
        end
      end

      def dropdown_label(option, index)
        [option['value'], translate(option['label'])]
      end


      def task_label(task_info)
        translate(task_info["question"] || task_info["instruction"])
      end

      def tool_label(task_info, drawn_item)
        tool = task_info["tools"] && task_info["tools"][drawn_item["tool"]]
        translate(tool["label"]) if tool
      end

      def answer_label
        answer_labels.first
      end

      def answer_labels
        Array.wrap(@current["value"]).map do |answer_idx|
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

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
        when /single|multiple|shortcut/
          simple
        when "text"
          text
        when "combo"
          combo
        when "dropdown"
          dropdown
        else
          @annotation
        end
      end

      private

      def drawing(task_info=task)
        {}.tap do |new_anno|
          new_anno['task'] = @current['task']
          new_anno['task_label'] = task_label(task_info)

          added_tool_lables = Array.wrap(@current["value"]).map do |drawn_item|
            if drawn_item.is_a?(Hash)
              tool_label = tool_label(task_info, drawn_item)
              drawn_item.merge("tool_label" => tool_label)
            else
              drawn_item
            end
          end

          new_anno["value"] = added_tool_lables
        end
      end

      def simple(task_info=task)
        {}.tap do |new_anno|
          new_anno['task'] = @current['task']
          new_anno['task_label'] = task_label(task_info)
          new_anno['value'] = ['multiple', 'shortcut'].include?(task_info['type']) ? answer_labels : answer_labels.first
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
          Array.wrap(annotation['value']).each do |subtask|
            @current = subtask
            task_info = get_task_info(subtask)
            new_anno['value'].push case task_info['type']
              when "drawing"
                drawing(task_info)
              when "single", "multiple"
                simple(task_info)
              when "text"
                text(task_info)
              when "combo"
                { error: "combo tasks cannot be nested" }
              when "dropdown"
                dropdown(task_info)
              else
                @current
              end
          end
        end
      end

      def dropdown(task_info=task)
        {}.tap do |new_anno|
          new_anno['task'] = @current['task']
          new_anno['value'] = task_info['selects'].map.with_index do |selects, index|
            dropdown_process_selects(selects, index)
          end
        end
      end

      def dropdown_process_selects(selects, index)
        answer = @current['value'][index]

        {}.tap do |drop_anno|
          drop_anno['select_label'] = selects['title']

          if selects['allowCreate']
            drop_anno['option'] = false
            drop_anno['value'] = @current['value'][index]['value']
          end

          selected_option = dropdown_find_selected_option(selects, answer)
          if selected_option
            drop_anno['option'] = true
            drop_anno['value'] = selected_option['value']
            drop_anno['label'] = translate(selected_option['label'])
          end
        end
      end

      def dropdown_find_selected_option(selects, answer)
        selects['options'].each do |key, options|
          options.each do |option|
            return option if option['value'] == answer['value']
          end
        end
        nil
      end

      def task_label(task_info)
        translate(task_info["question"] || task_info["instruction"])
      end

      def tool_label(task_info, tool)
        tool_index = tool["tool"]
        have_tool_lookup_info = !!(task_info["tools"] && tool_index)
        known_tool = have_tool_lookup_info && task_info["tools"][tool_index]
        translate(known_tool["label"]) if known_tool
      end

      def answer_labels
        Array.wrap(@current["value"]).map do |answer_idx|
          begin
            task_answer = workflow_at_version.tasks[@current['task']]['answers'][answer_idx]
            answer_string = task_answer['label']
            translate(answer_string)
          rescue TypeError, NoMethodError
            "unknown answer label"
          end
        end
      end

      def translate(string)
        @translations ||= primary_content_at_version.strings
        @translations[string]
      end

      def primary_content_at_version
        cache.workflow_content_at_version(classification.workflow.primary_content, content_version)
      end

      def workflow_at_version
        cache.workflow_at_version(classification.workflow, workflow_version)
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
      rescue
        {}
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

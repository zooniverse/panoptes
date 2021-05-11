module Formatter
  module Csv
    class AnnotationForCsv
      attr_reader :classification, :annotation, :cache, :workflow_information

      def initialize(classification, annotation, cache)
        @classification = classification
        @annotation = annotation.dup.with_indifferent_access
        @current = @annotation.dup
        @cache = cache
        @workflow_information = WorkflowInformation.new(cache, classification.workflow, classification.workflow_version)
      end

      def to_h
        task = workflow_information.task(annotation['task'])
        case task['type']
        when 'drawing'
          drawing(task)
        when /single|multiple|shortcut/
          simple(task)
        when 'text'
          text(task)
        when 'dropdown'
          dropdown(task)
        when 'combo'
          combo # combo iterates over the submitted task annotation values
        else
          @annotation
        end
      rescue ClassificationDumpCache::MissingWorkflowVersion => error
        Honeybadger.notify(error, context: {classification_id: classification.id})
        @annotation
      end

      private

      def drawing(task_info)
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

      def simple(task_info)
        {}.tap do |new_anno|
          new_anno['task'] = @current['task']
          new_anno['task_label'] = task_label(task_info)
          new_anno['value'] =
            if %w[multiple shortcut].include?(task_info['type'])
              answer_labels
            else
              answer_labels.first
            end
        end
      end

      def text(task_info)
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

      def dropdown(task_info)
        {}.tap do |new_anno|
          new_anno['task'] = @current['task']
          new_anno['value'] = task_info['selects'].map.with_index do |selects, index|
            dropdown_process_selects(selects, index)
          end
        end
      end

      def dropdown_process_selects(selects, index)
        answer_value = nil
        if answer = @current['value'][index]
          answer_value = answer['value']
        end

        {}.tap do |drop_anno|
          drop_anno['select_label'] = selects['title']

          if selects['allowCreate']
            drop_anno['option'] = false
            drop_anno['value'] = answer_value
          end

          if selected_option = dropdown_find_selected_option(selects, answer_value)
            drop_anno['option'] = true
            drop_anno['value'] = selected_option['value']
            drop_anno['label'] = workflow_information.string(selected_option['label'])
          end
        end
      end

      def dropdown_find_selected_option(selects, answer_value)
        selects['options'].each do |key, options|
          options.each do |option|
            return option if option['value'] == answer_value
          end
        end
        nil
      end

      def task_label(task_info)
        workflow_information.string(task_info['question'] || task_info['instruction'])
      end

      def tool_label(task_info, tool)
        tool_index = tool["tool"]
        have_tool_lookup_info = !!(task_info["tools"] && tool_index)
        known_tool = have_tool_lookup_info && task_info["tools"][tool_index]
        workflow_information.string(known_tool['label']) if known_tool
      end

      def answer_labels
        Array.wrap(@current["value"]).map do |answer_idx|
          begin
            task_answer = workflow_at_version.tasks[@current['task']]['answers'][answer_idx]
            answer_string = task_answer['label']
            workflow_information.string(answer_string)
          rescue TypeError, NoMethodError
            "unknown answer label"
          end
        end
      end

      def workflow_at_version
        workflow_information.at_version
      end

      # used in combo task to protect against invalid annotations
      # i.e. bad annotation data from tropical sweden project
      # https://github.com/zooniverse/panoptes/blob/5928d94cffb424e68aec480c619271d0783bb0dc/spec/lib/formatter/csv/annotation_for_csv_spec.rb#L196-L210
      def get_task_info(task)
        task_key = task['task']
        workflow_information.task(task_key)
      rescue TypeError
        {}
      end
    end
  end
end

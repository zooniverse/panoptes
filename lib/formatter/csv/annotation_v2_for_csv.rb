
# frozen_string_literal: true

# Copy of the AnnotationForCsv class bringing over the default annotation formatting behaviour
# an updating to handel the "classifier_version"=>"2.0" as noted on
# classification metadata FEM classifications vs PFE (v1 and missing on the metadata)
#
# Overtime this class will evolve behaviour to handle the distinct classification annotation formats
# if it doesn't these two behaviours can be refactored for collaborating classes
# to provide csv converstion of the differing annotation formats
module Formatter
  module Csv
    class AnnotationV2ForCsv
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
      rescue ClassificationDumpCache::MissingWorkflowVersion => error
        Honeybadger.notify(error, context: {classification_id: classification.id})
        @annotation
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
        # TODO raise if annotation format is not @current['taskType'] == "dropdown-simple"
        # and there is only 1 select (dropdown) configured for the task.
        # as FEM only supports simple dropdowns currently and
        # the project builders are using PFE lab dropdown workflows to configure
        # https://github.com/zooniverse/front-end-monorepo/blob/master/docs/arch/adr-30.md#consequences
        # https://github.com/zooniverse/front-end-monorepo/tree/master/packages/lib-classifier/src/plugins/tasks/SimpleDropdownTask/models/helpers/legacyDropdownAdapter

        {}.tap do |new_anno|
          new_anno['task'] = @current['task']
          # there should only be one dropdown for these v2 workflow annotations
          # note each PFE lab task `select` is an actual dropdown in the UI
          selected_dropdown = task_info['selects'].first
          new_anno['value'] = dropdown_process_select(selected_dropdown)
        end
      end

      def dropdown_process_select(selected_dropdown)
        answer_value = @current.dig('value', 'selection') || nil

        {}.tap do |drop_anno|
          drop_anno['select_label'] = selected_dropdown['title']

          if selected_dropdown['allowCreate']
            drop_anno['option'] = false
            drop_anno['value'] = answer_value
          end

          if (selected_option = dropdown_find_selected_option(selected_dropdown, answer_value))
            drop_anno['option'] = true
            drop_anno['value'] = selected_option['value']
            drop_anno['label'] = translate(selected_option['label'])
          end
        end
      end

      def dropdown_find_selected_option(selected_dropdown, answer_value)
        flattened_dropdown_option_values = selected_dropdown['options'].values.flatten
        flattened_dropdown_option_values.find do |option|
          option['value'] == answer_value
        end
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
        @translations ||= workflow_at_version.strings
        @translations[string]
      end

      def workflow_at_version
        cache.workflow_at_version(classification.workflow, workflow_version, content_version)
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

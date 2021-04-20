
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
      class V2DropdownSimpleTaskError < StandardError; end

      attr_reader :classification, :annotation, :cache, :default_formatter

      def initialize(classification, annotation, cache, default_formatter=nil)
        @classification = classification
        @annotation = annotation.dup.with_indifferent_access
        @current = @annotation.dup
        @cache = cache
        # setup a default formatter for unknown v2 annotation types (i.e. all the v1 tasks)
        @default_formatter = default_formatter || AnnotationForCsv.new(@classification, @annotation, @cache)
      end

      def to_h
        return dropdown(task) if task['type'] == 'dropdown'

        # use the default formatter (v1) for non v2 specific task types
        # as time goes on behaviour will eventually move from default formatter
        # to above in order to handle the newer v2 specific annotation formats
        default_formatter.to_h
      end

      private

      def dropdown(task_info)
        ensure_v2_dropdown_task_format(task_info)

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

      # raise if annotation format is not @current['taskType'] == "dropdown-simple"
      # and there is only 1 select (dropdown) configured for the task.
      # as FEM only supports simple dropdowns currently and
      # the project builders are using PFE lab dropdown workflows to configure
      # https://github.com/zooniverse/front-end-monorepo/blob/master/docs/arch/adr-30.md#consequences
      # https://github.com/zooniverse/front-end-monorepo/tree/master/packages/lib-classifier/src/plugins/tasks/SimpleDropdownTask/models/helpers/legacyDropdownAdapter
      def ensure_v2_dropdown_task_format(task_info)
        return unless task_info['selects'].count > 1

        raise V2DropdownSimpleTaskError, 'Dropdown task has multiple selects and is not conformant to v2 dropdown-simple task type - aborting'
      end

      # these can be extracted to a common collaborator / base class?
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

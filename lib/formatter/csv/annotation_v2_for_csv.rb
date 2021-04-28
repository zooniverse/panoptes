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

      attr_reader :classification, :annotation, :cache, :default_formatter, :workflow_information

      def initialize(classification, annotation, cache, default_formatter=nil)
        @classification = classification
        @annotation = annotation.dup.with_indifferent_access
        @current = @annotation.dup
        @cache = cache
        # setup a default formatter for unknown v2 annotation types (i.e. all the v1 tasks)
        @default_formatter = default_formatter || AnnotationForCsv.new(@classification, @annotation, @cache)
        @workflow_information = WorkflowInformation.new(cache, classification.workflow, classification.workflow_version)
      end

      def to_h
        task = workflow_information.task(annotation['task'])
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

          # `allowCreate` means a volunteer may override the selects and create free text
          # however they may still choose to use a supplied select option from the wf tasks
          # hence below we still have to check the answer is a known select option
          if selected_dropdown['allowCreate']
            drop_anno['option'] = false # this means volunteer created value
            drop_anno['value'] = answer_value
          end

          if answer_value && (selected_option = dropdown_find_selected_option(selected_dropdown, answer_value))
            drop_anno['option'] = true # this means volunteer selected a provided worfklow option select
            drop_anno['value'] = selected_option['value']
            drop_anno['label'] = workflow_information.string(selected_option['label'])
          end
        end
      end

      def dropdown_find_selected_option(selected_dropdown, answer_index)
        flattened_dropdown_option_values = selected_dropdown['options'].values.flatten
        found_option = flattened_dropdown_option_values[answer_index]
        return unless found_option

        # override the value in the workflow's task option representation
        # to preserve the supplied answer index for downstream consumers
        found_option.merge('value' => answer_index)
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
    end
  end
end

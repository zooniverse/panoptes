# frozen_string_literal: true

module Formatter
  module Csv
    module V2
      class DropdownAnnotation
        class TaskError < StandardError; end
        attr_reader :task_info, :annotation, :workflow_information

        def initialize(task_info, annotation, workflow_information)
          @task_info = task_info
          @annotation = annotation
          @workflow_information = workflow_information

          ensure_v2_dropdown_task_format(task_info)
        end

        def format
          dropdown_annotation = {}
          dropdown_annotation['task'] = annotation['task']
          dropdown_annotation['task_type'] = annotation['taskType']
          # there should only be one dropdown for these v2 workflow annotations
          # note each PFE lab task `select` is an actual dropdown in the UI
          selected_dropdown = task_info['selects'].first
          selection_value = annotation.dig('value', 'selection')
          dropdown_annotation.merge(
            'value' => dropdown_process_select(selected_dropdown, selection_value),
          )
        end

        def dropdown_process_select(selected_dropdown, selected_value)
          dropdown_anno = { 'select_label' => selected_dropdown['title'] }
          return dropdown_anno unless selected_value

          dropdown_anno = process_volunteer_provided_option(
            selected_dropdown['allowCreate'],
            dropdown_anno,
            selected_value
          )

          selected_option = dropdown_find_selected_option(selected_dropdown, selected_value)
          process_provided_select_options(selected_option, dropdown_anno)
        end

        # `allowCreate` means a volunteer may override the selects and create free text
        # however they may still choose to use a supplied select option from the wf tasks
        # hence below we still have to check the answer is a known select option
        def process_volunteer_provided_option(allow_create, annotation, selected_value)
          return annotation unless allow_create

          annotation.merge(
            'option' => false, # this means volunteer created value for downstream services
            'value' => selected_value
          )
        end

        def process_provided_select_options(selected_option, annotation)
          return annotation unless selected_option

          annotation.merge(
            'option' => true, # this means volunteer selected a provided worfklow option select
            'value' => selected_option['value'],
            'label' => workflow_information.string(selected_option['label'])
          )
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

          raise TaskError, 'Dropdown task has multiple selects and is not conformant to v2 dropdown-simple task type - aborting'
        end
      end
    end
  end
end
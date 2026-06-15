# frozen_string_literal: true

module Formatter
  module Csv
    module V2
      class DrawingAnnotation
        attr_reader :task_info, :annotation, :workflow_information

        def initialize(task_info, annotation, workflow_information)
          @task_info = task_info
          @annotation = annotation
          @workflow_information = workflow_information
        end

        def format
          {
            'task' => annotation['task'],
            'task_label' => task_label,
            'value' => drawing_values
          }
        end

        private

        def drawing_values
          Array.wrap(annotation['value']).map do |drawn_item|
            next drawn_item unless drawn_item.is_a?(Hash)

            drawn_item.merge('tool_label' => tool_label(drawn_item))
          end
        end

        def task_label
          workflow_information.string(task_info['question'] || task_info['instruction'])
        end

        def tool_label(drawn_item)
          tool_index = drawn_item['toolIndex'] || drawn_item['tool_index']
          return unless tool_index

          known_tool = task_info['tools'] && task_info['tools'][tool_index]
          workflow_information.string(known_tool['label']) if known_tool
        end
      end
    end
  end
end

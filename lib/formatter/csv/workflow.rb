module Formatter
  module Csv
    class Workflow
      attr_reader :workflow

      JSON_FIELDS = [:tasks, :aggregation, :strings ].freeze

      def headers
        %w(workflow_id display_name version active classifications_count pairwise
        grouped prioritized primary_language first_task tutorial_subject_id
        retired_set_member_subjects_count tasks retirement aggregation strings)
      end

      def to_rows(workflow)
        [to_array(workflow)]
      end

      private

      def to_array(workflow)
        @workflow = workflow
        headers.map { |header| send(header) }
      end

      def workflow_id
        workflow.id
      end

      def version
        current_version_number.to_i
      end

      def retirement
        workflow.retirement_with_defaults.to_json
      end

      def method_missing(method, *args, &block)
        value = workflow.send(method, *args, &block)
        formatted_value(method, value)
      end

      def formatted_value(method, value)
        if JSON_FIELDS.include?(method)
          value.to_json
        else
          value
        end
      end
    end
  end
end

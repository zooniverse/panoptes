module Formatter
  module Csv
    class Workflow
      attr_reader :workflow_version

      JSON_FIELDS = [:tasks, :aggregation, :strings ].freeze

      def headers
        %w(workflow_id display_name version minor_version active classifications_count pairwise
        grouped prioritized primary_language first_task tutorial_subject_id
        retired_set_member_subjects_count tasks retirement aggregation strings)
      end

      def to_rows(workflow_version)
        [to_array(workflow_version)]
      end

      private

      def to_array(workflow_version)
        @workflow_version = workflow_version
        headers.map { |header| send(header) }
      end

      def workflow_id
        workflow.id
      end

      def retirement
        workflow.retirement_with_defaults.to_json
      end

      def method_missing(method, *args, &block)
        value = if workflow_version.respond_to?(method)
                  workflow_version.public_send(method, *args, &block)
                else
                  workflow_version.workflow.public_send(method, *args, &block)
                end

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

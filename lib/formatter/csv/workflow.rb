module Formatter
  module Csv
    class Workflow
      attr_reader :workflow

      JSON_FIELDS = [:tasks, :aggregation ].freeze

      def self.headers
        %w(workflow_id display_name version active classifications_count pairwise
        grouped prioritized primary_language first_task tutorial_subject_id
        retired_set_member_subjects_count tasks retirement aggregation)
      end

      def to_array(workflow)
        @workflow = workflow
        self.class.headers.map { |header| send(header) }
      end

      private

      def workflow_id
        workflow.id
      end

      def version
        # Deals with old versions of workflows, so can't use the cached current_version_number
        ModelVersion.version_number(workflow)
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

module Formatter
  module Csv
    class Workflow
      attr_reader :workflow

      JSON_FIELDS = [:tasks, :retirement, :aggregation ].freeze

      def self.workflow_headers
        %w(workflow_id display_name version active classifications_count pairwise
        grouped prioritized primary_language first_task tutorial_subject_id
        retired_set_member_subjects_count tasks retirement aggregation)
      end

      def to_array(workflow)
        @workflow = workflow
        self.class.workflow_headers.map { |header| send(header) }
      end

      private

      def workflow_id
        workflow.id
      end

      def version
        ModelVersion.version_number(workflow)
      end

      def method_missing(method, *args, &block)
        value = @workflow.send(method, *args, &block)
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

module Formatter
  module Csv
    class Workflow
      attr_reader :workflow_version

      JSON_FIELDS = %i[tasks strings].freeze

      def headers
        %w[workflow_id display_name version active classifications_count pairwise
           grouped prioritized primary_language first_task tutorial_subject_id
           retired_set_member_subjects_count tasks retirement strings minor_version]
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

      def version
        workflow_version.major_number
      end

      def minor_version
        workflow_version.minor_number
      end

      def pairwise
        workflow.pairwise
      end

      def grouped
        workflow.grouped
      end

      def prioritized
        workflow.prioritized
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

module Formatter
  module Csv
    class WorkflowContent
      attr_reader :workflow_content

      delegate :language, to: :workflow_content

      def self.headers
        %w(workflow_content_id workflow_id language version strings)
      end

      def to_array(workflow_content)
        @workflow_content = workflow_content
        self.class.headers.map { |header| send(header) }
      end

      private

      def workflow_content_id
        workflow_content.id
      end

      def workflow_id
        workflow_content.workflow.id
      end

      def version
        # Deals with old versions of contents, so can't use the cached current_version_number
        ModelVersion.version_number(workflow_content)
      end

      def strings
        workflow_content.strings.to_json
      end
    end
  end
end

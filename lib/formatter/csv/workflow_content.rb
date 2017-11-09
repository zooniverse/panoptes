module Formatter
  module Csv
    class WorkflowContent
      attr_reader :workflow_content

      delegate :language, to: :workflow_content

      def headers
        %w(workflow_content_id workflow_id language version strings)
      end

      def to_rows(workflow_content)
        [to_array(workflow_content)]
      end

      private

      def to_array(workflow_content)
        @workflow_content = workflow_content
        headers.map { |header| send(header) }
      end

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

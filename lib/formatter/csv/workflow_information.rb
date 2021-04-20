# frozen_string_literal: true

module Formatter
  module Csv
    class WorkflowInformation

      attr_reader :cache, :workflow, :workflow_version, :content_version

      def initialize(cache, workflow, workflow_version_string)
        @cache = cache
        @workflow = workflow
        wf_version_strings = workflow_version_string.split('.')
        @workflow_version = wf_version_strings[0].to_i
        @content_version = wf_version_strings[1].to_i
      end

      def workflow_at_version
        cache.workflow_at_version(workflow, workflow_version, content_version)
      end

      def workflow_string(string)
        @workflow_string ||= workflow_at_version.strings
        @workflow_string[string]
      end

      def workflow_task(task_key_to_find)
        task_annotation = workflow_at_version.tasks.find do |key, _task|
          key == task_key_to_find
        end
        task_annotation.try(:last) || {}
      end
    end
  end
end

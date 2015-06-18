module Formatter
  module Csv
    class Subject
      attr_reader :sms, :project

      def self.project_headers
        %w(subject_id project_id workflow_ids subject_set_id metadata classifications_by_workflow retired_in_workflow)
      end

      def initialize(project)
        @project = project
      end

      def to_array(sms)
        @sms = sms
        self.class.project_headers.map do |header|
          send(header)
        end
      end

      private

      def project_id
        project.id
      end

      def workflow_ids
        sms.subject_set.workflows.pluck(:id).to_json
      end

      def subject_id
        sms.subject_id
      end

      def subject_set_id
        sms.subject_set_id
      end

      def retired_in_workflow
        sms.retired_workflow_ids.to_json
      end

      def metadata
        sms.subject.metadata.to_json
      end

      def classifications_by_workflow
        sms.subject_set.workflows.map do |workflow|
          count = SubjectWorkflowCount.find_by(set_member_subject: sms, workflow: workflow)
            .try(:classifications_count) || 0
          {workflow.id => count}
        end.reduce(&:merge).to_json
      end
    end
  end
end

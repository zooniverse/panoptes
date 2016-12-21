module Formatter
  module Csv
    class Subject
      attr_reader :subject, :project, :project_workflow_ids

      def self.headers
        %w(subject_id project_id workflow_ids subject_set_ids metadata locations
           classifications_by_workflow retired_in_workflow)
      end

      def initialize(project)
        @project = project
        @project_workflow_ids = project.workflows.pluck(:id)
      end

      def to_array(subject)
        @subject = subject
        self.class.headers.map do |header|
          send(header)
        end
      end

      private

      def subject_id
        subject.id
      end

      def subject_set_ids
        subject.subject_set_ids.to_json
      end

      def project_id
        project.id
      end

      def workflow_ids
        subject_workflow_statuses.map(&:workflow_id).to_json
      end

      def locations
        {}.tap do |locs|
          subject.ordered_locations.each_with_index.map do |loc, index|
            locs[index] = loc.get_url
          end
        end.to_json
      end

      def retired_in_workflow
        retired = subject_workflow_statuses.select do |sws|
          sws.retired?
        end
        retired.map(&:workflow_id).to_json
      end

      def metadata
        subject.metadata.to_json
      end

      def classifications_by_workflow
        workflow_counts = subject_workflow_statuses.map do |sws|
          count = (sws.classifications_count || 0)
          {sws.workflow_id => count}
        end
        workflow_counts.reduce(&:merge).to_json
      end

      def subject_workflow_statuses
        @swses ||= SubjectWorkflowStatus
          .by_subject(subject.id)
          .where(workflow_id: project_workflow_ids)
          .to_a
      end
    end
  end
end

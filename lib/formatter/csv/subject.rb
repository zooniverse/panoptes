module Formatter
  module Csv
    class Subject
      attr_reader :sms, :project

      delegate :subject_id, :subject_set_id, to: :sms

      def self.headers
        %w(subject_id project_id workflow_ids subject_set_id metadata locations
           classifications_by_workflow retired_in_workflow)
      end

      def initialize(project)
        @project = project
      end

      def to_array(sms)
        @sms = sms
        self.class.headers.map do |header|
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

      def locations
        subject_locs = sms.subject.locations.order("\"media\".\"metadata\"->>'index' ASC")
        {}.tap do |locs|
          subject_locs.each_with_index.map do |loc, index|
            locs[index] = loc.get_url
          end
        end.to_json
      end

      def retired_in_workflow
        SubjectWorkflowCount.retired.where(subject_id: subject_id).pluck(:workflow_id).to_json
      end

      def metadata
        sms.subject.metadata.to_json
      end

      def classifications_by_workflow
        sms.subject_set.workflows.map do |workflow|
          count = SubjectWorkflowCount.by_subject_workflow(subject_id, workflow.id)
            .try(:classifications_count) || 0
          {workflow.id => count}
        end.reduce(&:merge).to_json
      end
    end
  end
end

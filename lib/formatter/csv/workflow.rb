module Formatter
  module Csv
    class Workflow
      attr_reader :workflow, :project
      #
      # delegate :subject_id, :subject_set_id, to: :sms

      def self.project_headers
        %w(workflow_id display_name version_num active classifications_count pairwise grouped prioritized primary_language first_task tutorial_subject_id retired_set_member_subjects_count tasks retirement aggregation)
      end

      def initialize(project)
        @project = project
      end

      def to_array(workflow)
        @workflow = workflow
        self.class.project_headers.map do |header|
          send(header)
          #add versioning here
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
        SubjectWorkflowCount.where(set_member_subject: sms)
          .where.not(retired_at: nil)
          .pluck(:workflow_id)
          .to_json
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

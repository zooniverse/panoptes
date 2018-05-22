module Formatter
  module Csv
    class Subject
      attr_reader :subject, :project, :project_workflow_ids

      def initialize(project)
        @project = project
        @project_workflow_ids = project.workflows.pluck(:id)
      end

      def headers
        %w(subject_id project_id workflow_id subject_set_id metadata locations
           classifications_count retired_at retirement_reason)
      end

      def to_rows(subject)
        @subject = subject
        reset_the_sws_memoizer_for_the_new_subject

        rows = []

        linked_workflows_and_sets(subject).each do |subject_workflow_set_link|
          workflow_id = subject_workflow_set_link.workflow_id
          rows << HashWithIndifferentAccess.new(
            subject_id: subject_workflow_set_link.subject.id,
            project_id: project_id,
            workflow_id: workflow_id,
            subject_set_id: subject_workflow_set_link.subject_set_id,
            metadata: metadata,
            locations: locations,
            classifications_count: classifications_count(workflow_id),
            retired_at: retired_at(workflow_id),
            retirement_reason: retirement_reason(workflow_id)
          )
        end

        rows.map { |row| row.values_at(*headers) }
      end

      private

      def subject_id
        subject.id
      end

      def sorted_subject_set_ids(subject)
        if subject.subject_set_ids.present?
          subject.subject_set_ids.sort
        else
          []
        end
      end

      def subject_set_ids
        subject.subject_set_ids.to_json
      end

      def project_id
        project.id
      end

      def sorted_project_workflow_ids
        if @project_workflow_ids.present?
          @project_workflow_ids.sort
        else
          [nil]
        end
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

      def retired_at(workflow_id)
        subject_workflow_status = subject_workflow_statuses[workflow_id]
        subject_workflow_status&.retired_at
      end

      def retirement_reason(workflow_id)
        subject_workflow_status = subject_workflow_statuses[workflow_id]
        subject_workflow_status&.retirement_reason
      end

      def metadata
        subject.metadata.to_json
      end

      def classifications_count(workflow_id)
        subject_workflow_status = subject_workflow_statuses[workflow_id]
        subject_workflow_status&.classifications_count || 0
      end

      def reset_the_sws_memoizer_for_the_new_subject
        @subject_workflow_statuses = nil
      end

      def subject_workflow_statuses
        @subject_workflow_statuses ||=
          SubjectWorkflowStatus.by_subject(subject.id)
          .where(workflow_id: project_workflow_ids)
          .to_a
          .index_by(&:workflow_id)
      end

      def linked_workflows_and_sets(subject)
        subject_set_ids = sorted_subject_set_ids(subject)
        if subject_set_ids.empty?
          [ SubjectWorkflowSetLinks.new(nil, nil, subject) ]
        else
          subject_workflow_set_links = []
          set_workflow_links = subject_set_workflow_links(subject_set_ids)

          subject_set_ids.each do |set_id|
            set_workflow_links = set_workflow_links[set_id] || [ SubjectSetsWorkflow.new(subject_set_id: set_id) ]
            set_workflow_links.each do |ssw|
              subject_workflow_set_links << SubjectWorkflowSetLinks.new(
                ssw.workflow_id, ssw.subject_set_id, subject
              )
            end
          end

          subject_workflow_set_links
        end
      end

      def subject_set_workflow_links(subject_set_ids)
        SubjectSetsWorkflow.where(
          workflow_id: project_workflow_ids,
          subject_set_id: subject_set_ids
        ).group_by(&:subject_set_id)
      end

      class SubjectWorkflowSetLinks
        attr_reader :workflow_id, :subject_set_id, :subject

        def initialize(workflow_id, subject_set_id, subject)
          @workflow_id = workflow_id
          @subject_set_id = subject_set_id
          @subject = subject
        end
      end
    end
  end
end

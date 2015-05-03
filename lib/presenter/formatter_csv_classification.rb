module Formatter
  module CSV
    class Classification
      attr_reader :classification, :project, :show_user_id

      delegate :workflow_id, :created_at, :gold_standard, to: :classification

      def self.project_headers
        %w( user_id user_ip workflow_id created_at
            gold_standard expert metadata annotations
            subject_data )
      end

      def initialize(project, show_user_id: false)
        @project = project
        @show_user_id = show_user_id
      end

      def to_array(classification)
        @classification = classification
        self.class.project_headers.map do |attribute|
          send(attribute)
        end
      end

      private

      def user_id
        user_id = classification.user_id
        return user_id if show_user_id
        user_id.hash
      end

      def user_ip
        classification.user_ip.to_s
      end

      def subject_data
        {}.tap do |subjects_and_metadata|
          subjects = Subject.where(id: classification.subject_ids)
          subjects.each do |subject|
            subjects_and_metadata[subject.id] = subject.metadata
          end
        end.to_json
      end

      def metadata
        classification.metadata.to_json
      end

      def annotations
        classification.annotations.to_json
      end

      def expert
        classification.expert_classifier
      end
    end
  end
end

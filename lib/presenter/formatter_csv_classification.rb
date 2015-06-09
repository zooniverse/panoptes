module Formatter
  module CSV
    class Classification
      attr_reader :classification, :project, :obfuscate, :salt

      delegate :workflow_id, :created_at, :gold_standard, :workflow_version, to: :classification

      def self.project_headers
        %w( user_name user_ip workflow_id created_at
            gold_standard expert metadata annotations
            subject_data workflow_version )
      end

      def initialize(project, obfuscate_private_details: true)
        @project = project
        @obfuscate = obfuscate_private_details
        @salt = Time.now.to_i
      end

      def to_array(classification)
        @classification = classification
        self.class.project_headers.map do |attribute|
          send(attribute)
        end
      end

      private

      def user_name
        if user = classification.user
          user.login
        else
          "not logged in"
        end
      end

      def user_ip
        obfuscate_value(classification.user_ip.to_s)
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

      def obfuscate_value(value)
        if obfuscate
          Digest::SHA1.hexdigest("#{value}#{salt}")
        else
          value
        end
      end
    end
  end
end

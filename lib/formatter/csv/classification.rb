module Formatter
  module Csv
    class Classification
      attr_reader :classification, :project, :obfuscate, :salt

      delegate :user_id, :workflow, :workflow_id, :created_at, :gold_standard,
        :workflow_version, to: :classification

      def self.headers
        %w(user_name user_id user_ip workflow_id workflow_name workflow_version
           created_at gold_standard expert metadata annotations subject_data)
      end

      def initialize(project, obfuscate_private_details: true)
        @project = project
        @obfuscate = obfuscate_private_details
        @salt = Time.now.to_i
      end

      def to_array(classification)
        @classification = classification
        self.class.headers.map do |attribute|
          send(attribute)
        end
      end

      private

      def user_name
        if user = classification.user
          user.login
        else
          "not-logged-in-#{hash_value(classification.user_ip.to_s)}"
        end
      end

      def user_ip
        obfuscate_value(classification.user_ip.to_s)
      end

      def subject_data
        {}.tap do |subjects_and_metadata|
          subjects = ::Subject.where(id: classification.subject_ids)
          subjects.each do |subject|
            retired_data = { retired: subject.retired_for_workflow?(workflow) }
            subjects_and_metadata[subject.id] = retired_data.reverse_merge!(subject.metadata)
          end
        end.to_json
      end

      def metadata
        classification.metadata.to_json
      end

      def annotations
        classification.annotations.map do |annotation|
          AnnotationForCsv.new(classification, annotation).to_h
        end.to_json
      end

      def expert
        classification.expert_classifier
      end

      def workflow_name
        workflow.display_name
      end

      def obfuscate_value(value)
        obfuscate ? hash_value(value) : value
      end

      def hash_value(value)
        Digest::SHA1.hexdigest("#{value}#{salt}")
      end
    end
  end
end

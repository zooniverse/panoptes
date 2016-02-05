module Formatter
  module Csv
    class Classification
      attr_reader :classification, :project, :cache, :obfuscate, :salt

      delegate :user_id, :workflow, :workflow_id, :created_at, :gold_standard,
        :workflow_version, to: :classification

      def self.headers
        %w(user_name user_id user_ip workflow_id workflow_name workflow_version
           created_at gold_standard expert metadata annotations subject_data)
      end

      def initialize(project, cache, hide_private_details: true)
        @project = project
        @cache = cache
        @obfuscate = hide_private_details
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
          "not-logged-in-#{secure_user_ip}"
        end
      end

      def user_ip
        if obfuscate
          secure_user_ip
        else
          classification.user_ip.to_s
        end
      end

      def subject_data
        {}.tap do |subjects_and_metadata|
          classification.subject_ids.map {|id| cache.subject(id) }.each do |subject|
            retired_data = { retired: cache.retired?(subject.id, workflow.id) }
            subjects_and_metadata[subject.id] = retired_data.reverse_merge!(subject.metadata)
          end
        end.to_json
      end

      def metadata
        classification.metadata.to_json
      end

      def annotations
        classification.annotations.map do |annotation|
          AnnotationForCsv.new(classification, annotation, cache).to_h
        end.to_json
      end

      def expert
        classification.expert_classifier
      end

      def workflow_name
        workflow.display_name
      end

      def secure_user_ip
        cache.secure_user_ip(classification.user_ip.to_s)
      end
    end
  end
end

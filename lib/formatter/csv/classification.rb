module Formatter
  module Csv
    class Classification
      attr_reader :classification, :cache, :salt

      delegate :user_id, :workflow, :workflow_id, :created_at, :gold_standard,
        :workflow_version, to: :classification

      def self.headers
        %w(classification_id user_name user_id user_ip workflow_id workflow_name workflow_version
           created_at gold_standard expert metadata annotations subject_ids)
      end

      def initialize(cache)
        @cache = cache
        @salt = Time.now.to_i
      end

      def to_array(classification)
        @classification = classification
        self.class.headers.map do |attribute|
          send(attribute)
        end
      end

      private

      def classification_id
        classification.id
      end

      def user_name
        if user = classification.user
          user.login
        else
          "not-logged-in-#{user_ip}"
        end
      end

      def user_ip
        cache.secure_user_ip(classification.user_ip.to_s)
      end

      def subject_ids
        classification_subject_ids.join(";")
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

      def classification_subject_ids
        cache.subject_ids_from_classification(classification.id)
      end
    end
  end
end

module Warehouse
  class ClassificationFormatter
    attr_reader :classification, :project, :cache, :obfuscate, :salt

    delegate :user_id, :project_id, :workflow, :workflow_id, :created_at, :updated_at,
      :completed, :gold_standard, :workflow_version, to: :classification

    def self.headers
      %w(classification_id user_name user_id user_ip project_id workflow_id workflow_name workflow_version
         created_at updated_at completed gold_standard expert metadata subject_data) + BasicTaskFormatter::COLUMNS.map(&:to_s)
    end

    def initialize(project, cache, obfuscate_private_details: true)
      @project = project
      @cache = cache
      @obfuscate = obfuscate_private_details
      @salt = Time.now.to_i
    end

    def to_array(classification)
      @classification = classification

      classification.annotations.flat_map do |annotation|
        Array.wrap(format_annotation(annotation)).map do |annotation_data|
          classification_data.merge(annotation_data).stringify_keys
        end
      end
    end

    private

    def classification_data
      {
        classification_id: classification_id,
        user_name: user_name,
        user_id: user_id,
        user_ip: user_ip,
        project_id: project_id,
        workflow_id: workflow_id,
        workflow_name: workflow_name,
        workflow_version: workflow_version,
        created_at: created_at,
        updated_at: updated_at,
        completed: completed,
        gold_standard: gold_standard,
        expert: expert,
        metadata: metadata,
        subject_data: subject_data
      }
    end

    def format_annotation(annotation)
      task_definition = tasks.fetch(annotation.fetch("task"), {})
      translations = cache.workflow_content_at_version(classification.workflow.primary_content.id, content_version).strings
      AnnotationFormatter.format(annotation, task_definition: task_definition, translations: translations)
    end

    def tasks
      @tasks = cache.workflow_at_version(classification.workflow_id, workflow_version).tasks
    end

    def workflow_version
      classification.workflow_version.split(".")[0].to_i
    end

    def content_version
      classification.workflow_version.split(".")[1].to_i
    end

    def classification_id
      classification.id
    end

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
        classification.subject_ids.map {|id| cache.subject(id) }.each do |subject|
          retired_data = { retired: cache.retired?(subject.id, workflow.id) }
          subjects_and_metadata[subject.id] = retired_data.reverse_merge!(subject.metadata)
        end
      end.to_json
    end

    def metadata
      classification.metadata.to_json
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

require 'serialization/v1_adapter'

module EventStreamSerializers
  class ClassificationSerializer < ActiveModel::Serializer
    def self.serialize(classification, options = {})
      serializer = new(classification)
      Serialization::V1Adapter.new(serializer, options)
    end

    attributes :id, :created_at, :updated_at, :user_ip, :workflow_version, :gold_standard,
               :expert_classifier, :annotations, :metadata

    belongs_to :project,          serializer: EventStreamSerializers::ProjectSerializer
    belongs_to :user,             serializer: EventStreamSerializers::UserSerializer
    belongs_to :workflow,         serializer: EventStreamSerializers::WorkflowSerializer
    belongs_to :workflow_content, serializer: EventStreamSerializers::WorkflowContentSerializer
    has_many   :subjects,         serializer: EventStreamSerializers::SubjectSerializer

    def workflow
      version = workflow_version.split(".")[0].to_i

      latest    = object.workflow
      versioned = latest.versions.offset(version).first.try(:reify)
      versioned || latest
    end

    def workflow_content
      version = workflow_version.split(".")[1].to_i

      latest    = object.workflow.primary_content
      versioned = latest.versions.offset(version).first.try(:reify)
      versioned || latest
    end

    def user_ip
      object.user_ip.to_s
    end

    def metadata
      object.metadata.merge(workflow_version: object.workflow_version)
    end
  end
end

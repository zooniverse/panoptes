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
    has_many   :subjects,         serializer: EventStreamSerializers::SubjectSerializer
    type 'classifications'

    def user_ip
      object.user_ip.to_s
    end

    def metadata
      object.metadata.merge(workflow_version: object.workflow_version)
    end
  end
end

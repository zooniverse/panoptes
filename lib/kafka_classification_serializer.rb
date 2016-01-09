require 'serialization/v1_adapter'

class KafkaClassificationSerializer < ActiveModel::Serializer
  def self.serialize(classification, options = {})
    serializer = new(classification)
    Serialization::V1Adapter.new(serializer, options)
  end

  attributes :id, :annotations, :created_at, :metadata

  belongs_to :project, serializer: KafkaProjectSerializer
  belongs_to :user, serializer: KafkaUserSerializer
  belongs_to :workflow, serializer: KafkaWorkflowSerializer
  has_many   :subjects, serializer: KafkaSubjectSerializer

  def metadata
    object.metadata.merge(workflow_version: object.workflow_version)
  end
end

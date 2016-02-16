require 'serialization/v1_adapter'

class KafkaClassificationSerializer < ActiveModel::Serializer
  def self.serialize(classification, options = {})
    serializer = new(classification)
    Serialization::V1Adapter.new(serializer, options)
  end

  attributes :id, :created_at, :updated_at, :user_ip, :annotations, :metadata

  belongs_to :project, serializer: KafkaProjectSerializer
  belongs_to :user, serializer: KafkaUserSerializer
  belongs_to :workflow, serializer: KafkaWorkflowSerializer
  has_many   :subjects, serializer: KafkaSubjectSerializer

  def user_ip
    object.user_ip.to_s
  end

  def metadata
    object.metadata.merge(workflow_version: object.workflow_version)
  end
end

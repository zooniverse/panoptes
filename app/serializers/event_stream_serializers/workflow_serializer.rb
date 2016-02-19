module EventStreamSerializers
  class WorkflowSerializer < ActiveModel::Serializer
    attributes :id, :created_at
  end
end

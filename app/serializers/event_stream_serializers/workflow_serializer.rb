module EventStreamSerializers
  class WorkflowSerializer < ActiveModel::Serializer
    attributes :id, :display_name, :created_at
  end
end

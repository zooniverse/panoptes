module EventStreamSerializers
  class WorkflowSerializer < ActiveModel::Serializer
    attributes :id, :display_name, :retirement, :created_at, :updated_at
    type :workflows
  end
end

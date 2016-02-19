module EventStream
  class WorkflowSerializer < ActiveModel::Serializer
    attributes :id, :created_at
  end
end

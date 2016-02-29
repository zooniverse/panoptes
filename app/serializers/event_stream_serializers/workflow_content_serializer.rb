module EventStreamSerializers
  class WorkflowContentSerializer < ActiveModel::Serializer
    attributes :id, :strings, :created_at, :updated_at
  end
end

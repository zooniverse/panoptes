module EventStreamSerializers
  class ProjectSerializer < ActiveModel::Serializer
    attributes :id, :display_name, :created_at
  end
end

module EventStreamSerializers
  class ProjectSerializer < ActiveModel::Serializer
    attributes :id, :display_name, :created_at, :updated_at
    type 'projects'
  end
end

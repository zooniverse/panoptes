module EventStream
  class ProjectSerializer < ActiveModel::Serializer
    attributes :id, :name, :created_at
  end
end

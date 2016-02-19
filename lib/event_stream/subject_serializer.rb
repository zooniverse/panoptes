module EventStream
  class SubjectSerializer < ActiveModel::Serializer
    attributes :id, :metadata, :created_at, :updated_at
  end
end

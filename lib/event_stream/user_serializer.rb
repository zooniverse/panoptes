module EventStream
  class UserSerializer < ActiveModel::Serializer
    attributes :id, :login
  end
end

module EventStreamSerializers
  class UserSerializer < ActiveModel::Serializer
    attributes :id, :login
  end
end

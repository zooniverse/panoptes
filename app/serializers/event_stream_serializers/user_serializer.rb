module EventStreamSerializers
  class UserSerializer < ActiveModel::Serializer
    attributes :id, :login
    type :users
  end
end

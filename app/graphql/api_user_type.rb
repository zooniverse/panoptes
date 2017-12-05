ApiUserType = GraphQL::ObjectType.define do
  name "ApiUser"

  field :id, !types.ID
  field :displayName, !types.String, property: :display_name
end

AvatarType = GraphQL::ObjectType.define do
  name "Avatar"

  field :url, !types.String, resolve: ->(obj, args, ctx) {
    obj.external_link || "//" + obj.src
  }
end

QueryRoot = GraphQL::ObjectType.define do
  name "QueryRoot"

  field :me, ApiUser::Type do
    resolve ->(obj, args, ctx) { ctx[:api_user] if ctx[:api_user].logged_in? }
  end

  field :organization do
    type OrganizationType
    argument :id, !types.ID, "Filter by organization ID"
    resolve ->(obj, args, ctx) {
      Organization.public_scope.find(args[:id])
    }
  end
end

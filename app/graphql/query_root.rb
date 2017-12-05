QueryRoot = GraphQL::ObjectType.define do
  name "QueryRoot"

  field :me, ApiUser::Type do
    resolve ->(obj, args, ctx) { ctx[:api_user] if ctx[:api_user].logged_in? }
  end

  field :organization do
    type Organization::Type
    argument :id, !types.ID, "Filter by organization ID"
    resolve ->(obj, args, ctx) {
      Organization.find(args[:id])
    }
  end
end

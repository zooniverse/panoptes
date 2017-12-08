QueryRoot = GraphQL::ObjectType.define do
  name "QueryRoot"

  field :me, ApiUserType do
    resolve ->(obj, args, ctx) { ctx[:api_user] if ctx[:api_user].logged_in? }
  end

  field :organization do
    type OrganizationType
    argument :id, !types.ID, "Filter by organization ID"
    resolve ->(obj, args, ctx) {
      ctx[:api_user]
        .do(:show)
        .to(Organization)
        .with_ids(args[:id])
        .scope.first
    }
  end
end

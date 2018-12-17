module Types
  class QueryType < Types::BaseObject
    field :me, ApiUserType, null: true
    field :organization, OrganizationType, null: true do
      argument :id, ID, required: true, description: "Filter by organization ID"
    end

    def me
      context[:api_user] if context[:api_user].logged_in?
    end

    def organization(id:)
      context[:api_user].scope(klass: Organization, action: :show, ids: id)
    end
  end
end

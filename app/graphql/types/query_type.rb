module Types
  class QueryType < Types::BaseObject
    field :me, ApiUserType, null: true

    field :organizations, OrganizationType.connection_type, null: false do
    end

    field :organization, OrganizationType, null: true do
      argument :id, ID, required: true, description: "Filter by organization ID"
    end

    field :projects, ProjectType.connection_type, null: false do
      argument :beta_requested, Boolean, required: false
      argument :beta_approved, Boolean, required: false
      argument :launch_requested, Boolean, required: false
      argument :launch_approved, Boolean, required: false
      argument :private, Boolean, required: false
      argument :state, String, required: false
      argument :mobile_friendly, Boolean, required: false
      argument :featured, Boolean, required: false
    end

    def me
      context[:api_user] if context[:api_user].logged_in?
    end

    def organization(id:)
      OrganizationPolicy.new(context[:api_user], Organization).scope_for(:show).where(id: id)
    end

    def organizations(**filters)
      apply_filters(Organization, filters)
    end

    def projects(**filters)
      scope = Project.active

      if Project.states.include?(filters[:state])
        filters[:state] = Project.states.include?(filters[:state])
      elsif filters[:state] == "live"
        # ensure we only look for projects missing the paused, finished enum states
        # this indicates we missed the true state of a project in the enum
        # we should have an active state instead of checking if state is null
        filters[:live] = true
        filters.delete(:state)
        scope = scope.where(state: nil)
      end

      apply_filters(scope, filters)
    end
  end
end

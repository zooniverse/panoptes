class Api::V1::OrganizationsController < Api::ApiController
  include FilterByOwner
  include FilterByCurrentUserRoles
  # include TranslatableResource
  include IndexSearch
  include AdminAllowed

  require_authentication :update, :create, :destroy, scopes: [:organization]

  resource_actions :show, :index, :create, :update, :deactivate
  schema_type :json_schema

  prepend_before_action :require_login,
    only: [:create, :update, :destroy]

  def create
    organizations = Organization.transaction do
      Array.wrap(params[:organizations]).map do |organization_params|
        Organizations::Create.with(api_user: api_user).run!(organization_params)
      end
    end

    created_resource_response(organizations)
  end

  def update
    Organization.transaction do
      Array.wrap(resource_ids).zip(Array.wrap(params[:organizations])).map do |organization_id, organization_params|
        Organizations::Update.with(api_user: api_user, id: organization_id).run!(organization_params)
      end
    end

    updated_resource_response
  end
end

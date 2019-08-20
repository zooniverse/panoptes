class Api::V1::OrganizationsController < Api::ApiController
  include JsonApiController::PunditPolicy
  include FilterByOwner
  include FilterByCurrentUserRoles
  include IndexSearch
  include FilterByTags
  include AdminAllowed
  include Slug
  include MediumResponse
  include SyncResourceTranslationStrings

  require_authentication :update, :create, :destroy, scopes: [:organization]

  resource_actions :show, :index, :create, :update, :deactivate

  prepend_before_action :require_login,
    only: [:create, :update, :destroy]

  schema_type :json_schema

  def create
    @created_resources = Organization.transaction(requires_new: true) do
      Array.wrap(create_params).map do |organization_params|
        operation = Organizations::Create.with(api_user: api_user)
        operation.run!(schema_create_params: organization_params)
      end
    end

    created_resource_response(created_resources)
  end

  def update
    @updated_resources = Organization.transaction(requires_new: true) do
      Array.wrap(resource_ids).zip(Array.wrap(update_params)).map do |organization_id, organization_params|
        update_operation = Organizations::Update.with(api_user: api_user, id: organization_id)
        update_operation.run!(schema_update_params: organization_params)
      end
    end

    updated_resource_response
  end

  def destroy
    Organization.transaction(requires_new: true) do
      Array.wrap(resource_ids).zip(Array.wrap(params[:organizations])).map do |organization_id, organization_params|
        Organizations::Destroy.with(api_user: api_user, id: organization_id).run!
      end
    end

    deleted_resource_response
  end
end

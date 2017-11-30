class Api::V1::OrganizationsController < Api::ApiController
  include FilterByOwner
  include FilterByCurrentUserRoles
  include IndexSearch
  include FilterByTags
  include AdminAllowed
  include Slug

  require_authentication :update, :create, :destroy, scopes: [:organization]

  resource_actions :show, :index, :create, :update, :deactivate

  prepend_before_action :require_login,
    only: [:create, :update, :destroy]

  CONTENT_PARAMS = [:description,
                    :title,
                    :introduction].freeze

  CONTENT_FIELDS = [:description,
                    :title,
                    :introduction,
                    :url_labels].freeze

  def create
    organizations = Organization.transaction(requires_new: true) do
      Array.wrap(params[:organizations]).map do |organization_params|
        Organizations::Create.with(api_user: api_user).run!(organization_params)
      end
    end

    created_resource_response(organizations)
  end

  def update
    Organization.transaction(requires_new: true) do
      Array.wrap(resource_ids).zip(Array.wrap(params[:organizations])).map do |organization_id, organization_params|
        wrapper = { organization_params: organization_params }
        Organizations::Update.with(api_user: api_user, id: organization_id).run!(wrapper)
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

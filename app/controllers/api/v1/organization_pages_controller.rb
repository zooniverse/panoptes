class Api::V1::OrganizationPagesController < Api::ApiController
  include Pages

  require_authentication :update, :create, :destroy, scopes: [:organization]

  def parent_resource
    :organization
  end

  def resource_id
    params[:organization_id]
  end

  def resource_name
    "organization_page"
  end
end

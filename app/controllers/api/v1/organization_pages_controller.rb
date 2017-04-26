class Api::V1::OrganizationPagesController < Api::ApiController
  require_authentication :update, :create, :destroy, scopes: [:organization]

  resource_actions :default

  schema_type :strong_params

  allowed_params :create, :url_key, :title, :content, :language
  allowed_params :update, :url_key, :title, :content, :language

  before_filter :set_language_from_header, only: [:index]

  def controlled_resources
    @controlled_resouces ||= super.where(organization: params[:organization_id])
  end

  protected

  def build_resource_for_create(create_params)
    create_params[:links] ||= {}
    create_params[:links][:organization] = params[:organization_id]
    super create_params
  end

  def link_header(resource)
    resource = resource.first
    send(:"api_#{ resource_name }_url", id: resource.id, organization_id: resource.organization_id)
  end

  def set_language_from_header
    params[:language] = "en"
  end
end

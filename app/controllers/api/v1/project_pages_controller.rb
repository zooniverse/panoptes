class Api::V1::ProjectPagesController < Api::ApiController
  require_authentication :update, :create, :destroy, scopes: [:project]

  resource_actions :default

  schema_type :strong_params

  allowed_params :create, :url_key, :title, :content, :language
  allowed_params :update, :url_key, :title, :content, :language

  before_filter :set_language_from_header, only: [:index]

  def controlled_resources
    @controlled_resouces ||= super.where(project: params[:project_id])
  end

  protected

  def build_resource_for_create(create_params)
    create_params[:links] ||= {}
    create_params[:links][:project] = params[:project_id]
    super create_params
  end

  def link_header(resource)
    resource = resource.first
    send(:"api_#{ resource_name }_url", id: resource.id, project_id: resource.project_id)
  end

  def set_language_from_header
    params[:language] = "en"
  end
end

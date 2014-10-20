class Api::V1::SubjectsController < Api::ApiController
  include JsonApiController
  include Versioned
  
  before_action :merge_cellect_host, only: :index
  doorkeeper_for :update, :create, :destroy, :version, :versions,
    scopes: [:subject]
  resource_actions :default

  def index
    render json_api: selector.create_response
  end

  private

  def build_resource_for_create(create_params)
    create_params[:links][:owner] = owner || api_user.user
    super(create_params)
  end

  private

  def merge_cellect_host
    params[:host] = cellect_host(params[:workflow_id])
  end

  def selector
    @selector ||= SubjectSelector.new(api_user, params)
  end

  def create_params
    params.require(:subjects)
      .permit(metadata: params[:subjects][:metadata].try(:keys),
              locations: params[:subjects][:locations].try(:keys),
              links: [:project, owner: [:id, :type]])
  end

  def update_params
    params.require(:subjects)
      .permit(metadata: params[:subjects][:metadata].try(:keys),
              locations: params[:subjects][:locations].try(:keys))
  end
end

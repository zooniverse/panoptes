class Api::V1::SubjectsController < Api::ApiController
  include JsonApiController
  include Versioned
  
  before_action :merge_cellect_host, only: :index
  doorkeeper_for :update, :create, :destroy, :version, :versions,
                 scopes: [:subject]
  resource_actions :default

  alias_method :subject, :controlled_resource

  def index
    render json_api: selector.create_response
  end

  private

  def create_response(subject)
    serializer.resource(subject, nil, post_urls: true)
  end

  def update_response
    render json_api: serializer.resource(subject, nil, post_urls: true)
  end

  def build_resource_for_create(create_params)
    locations = create_params.delete(:locations)
    create_params[:links][:owner] = owner || api_user.user
    subject = super(create_params)
    subject.save!
    subject.locations = locations
    subject
  end
  
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
              links: [:project, :subject_sets, owner: [:id, :type]])
  end

  def update_params
    params.require(:subjects)
      .permit(metadata: params[:subjects][:metadata].try(:keys),
              locations: params[:subjects][:locations].try(:keys),
              links: [:subject_sets])
  end
end

class Api::V1::SubjectsController < Api::ApiController
  include JsonApiController
  
  before_filter :require_login, only: [:update, :create, :destroy]
  doorkeeper_for :update, :create, :destroy, scopes: [:subject]
  access_control_for :update, :create, :destroy

  resource_actions :default

  def index
    if params[:sort] == 'random' && params.has_key?(:workflow_id)
      random_subjects
    elsif params.has_key?(:subject_set_id)
      query_subject_sets
    else
      super
    end
  end

  private

  def create_resource(create_params)
    create_params[:links][:owner] = owner || api_user.user
    super(create_params)
  end

  def query_subjects
    render json_api: serializer.resource(params)
  end

  def query_subject_sets
    render json_api: SetMemberSubjectSerializer.resource(params)
  end

  def random_subjects
    subject_ids = Cellect::Client.connection.get_subjects(**cellect_params).join(',')
    render json_api: SetMemberSubjectSerializer.page({id: subject_ids})
  end

  def cellect_params
    c_params = params.permit(:workflow_id, :subject_set_id, :limit, :sort)
      .slice(:workflow_id, :subject_set_id, :limit)
      .merge(user_id: api_user.try(:id),
             limit: 10,
             host: cellect_host(params[:workflow_id])) {|k, ov, nv| ov ? ov : nv}
    c_params[:group_id] = c_params.delete(:subject_set_id)
    c_params.symbolize_keys
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

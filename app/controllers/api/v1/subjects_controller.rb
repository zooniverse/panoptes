class Api::V1::SubjectsController < Api::ApiController
  doorkeeper_for :update, :create, :update, scopes: [:subject]

  def show
    render json_api: SubjectSerializer.page(params)
  end

  def index
    if params[:sort] == 'random' && params.has_key?(:workflow_id)
      random_subjects
    elsif params.has_key?(:subject_set_id)
      query_subject_sets
    else
      query_subjects
    end
  end

  def update

  end

  def create

  end

  def destroy

  end

  private

  def query_subjects
    render json_api: SubjectSerializer.resource(params)
  end

  def query_subject_sets
    render json_api: SetMemberSubjectSerializer.resource(params)
  end

  def random_subjects
    subject_ids = Cellect::Client.connection.get_subjects(**cellect_params).join(',')
    render json_api: SetMemberSubjectSerializer.page({id: subject_ids})
  end

  def cellect_params
    c_params = params.permit(:workflow_id, :subject_set_id, :limit)
      .merge(user_id: current_resource_owner.try(:id),
             limit: 10,
             host: cellect_host(params[:workflow_id])) {|k, ov, nv| ov ? ov : nv}
    c_params[:group_id] = c_params.delete(:subject_set_id)
    c_params.symbolize_keys
  end
end

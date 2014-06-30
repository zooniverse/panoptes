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
    {
      workflow_id: params[:workflow_id],
      user_id: current_resource_owner.try(:id),
      host: cellect_host,
      limit: params[:limit] || 10,
      group_id: params[:subject_set_id] || nil
    }
  end

  def cellect_host
    host = current_resource_owner.try(:cellect_host).try(:[], params[:workflow_id])
    host ||= Cellect::Client.choose_host
    host
  end
end 

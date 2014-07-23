class Api::V1::SubjectSetsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json_api: SubjectSetSerializer.resource(params)
  end

  def index
    render json_api: SubjectSetSerializer.page(params)
  end

  def update

  end

  def create
    subject_set = SubjectSet.new creation_params
    authorize subject_set.project, :update?
    subject_set.save!
    json_api_render( 201,
                     SubjectSetSerializer.resource(subject_set),
                     api_subject_set_url(subject_set) )
  end

  def destroy
    subject_set = SubjectSet.find params[:id]
    authorize subject_set.project, :destroy?
    subject_set.destroy!
    deleted_resource_response
  end

  private

  def creation_params
    params.require(:subject_set).permit :name, :project_id
  end
end

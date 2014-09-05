class Api::V1::SubjectSetsController < Api::ApiController
  doorkeeper_for :all
  access_control_for :create, :update, :destroy, resource_class: SubjectSet

  alias_method :subject_set, :controlled_resource

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
    subject_set.save!
    json_api_render( 201,
                     SubjectSetSerializer.resource(subject_set),
                     api_subject_set_url(subject_set) )
  end

  private

  def creation_params
    params.require(:subject_set).permit :name, :project_id
  end
end

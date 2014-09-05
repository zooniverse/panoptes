class Api::V1::SubjectSetsController < Api::ApiController
  before_filter :require_login, only: [:update, :destroy, :create]
  doorkeeper_for :create, :update, :destroy, scopes: [:project]
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

  private

  def create_params
    params.require(:subject_sets).permit(:name, :project_id)
  end
end

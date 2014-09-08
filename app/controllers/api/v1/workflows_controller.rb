class Api::V1::WorkflowsController < Api::ApiController
  before_filter :require_login, only: [:create, :update, :destroy]
  doorkeeper_for :update, :create, :delete, scopes: [:project]
  access_control_for :create, :update, :destroy, resource_class: Workflow

  alias_method :workflow, :controlled_resource

  def show
    load_cellect
    render json_api: WorkflowSerializer.resource(params)
  end

  def index
    render json_api: WorkflowSerializer.resource(params)
  end

  def update
    # TODO
  end

  private

  def create_params
    params.require(:workflows)
      .permit(:name,
              :project_id,
              :pairwise,
              :grouped,
              :prioritized,
              :primary_language,
              tasks: params[:workflows][:tasks].map(&:keys))
  end

  def load_cellect
    return unless api_user.logged_in?
    Cellect::Client.connection.load_user(**cellect_params)
  end

  def cellect_params
    {
      host: cellect_host(params[:id]),
      user_id: api_user.id,
      workflow_id: params[:id]
    }
  end
end

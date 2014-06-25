class Api::V1::WorkflowsController < Api::ApiController
  doorkeeper_for :all
  after_action :verify_authorized, except: [:index, :show]

  def show
    render json_api: WorkflowSerializer.resource(params)
  end

  def index
    render json_api: WorkflowSerializer.resource(params)
  end

  def update
    # TO-DO
  end

  def create
    workflow = Workflow.new creation_params
    authorize workflow.project, :update?
    workflow.save!
    json_api_render 201, WorkflowSerializer.resource(workflow)
  end

  def destroy
    workflow = Workflow.find params[:id]
    authorize workflow.project, :delete?
    workflow.destroy!
    deleted_resource_response
  end

  private

  def creation_params
    params.require(:workflow)
      .permit(:name, :project_id, :pairwise, :grouped, :prioritized)
      .merge tasks: params[:workflow][:tasks]
  end
end

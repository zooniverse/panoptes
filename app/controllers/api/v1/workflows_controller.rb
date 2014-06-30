class Api::V1::WorkflowsController < Api::ApiController
  doorkeeper_for :update, :create, :delete, scopes: [:project] 
  after_action :verify_authorized, except: :index

  def show
    workflow = Workflow.find(params[:id])
    authorize workflow.project, :read?
    load_cellect
    render json_api: WorkflowSerializer.resource(params)
  end

  def index
    render json_api: WorkflowSerializer.resource(params)
  end

  def update
    # TODO
  end

  def create
    workflow = Workflow.new creation_params
    authorize workflow.project, :update?
    workflow.save!
    json_api_render 201, WorkflowSerializer.resource(workflow)
  end

  def destroy
    workflow = Workflow.find params[:id]
    authorize workflow.project, :destroy?
    workflow.destroy!
    deleted_resource_response
  end

  private

  def creation_params
    params.require(:workflow)
      .permit(:name, :project_id, :pairwise, :grouped, :prioritized)
      .merge tasks: params[:workflow][:tasks]
  end

  def load_cellect
    return unless current_resource_owner
    Cellect::Client.connection.load_user(current_resource_owner.id, **cellect_params)
  end

  def cellect_params
    {
      host: cellect_host(params[:id]),
      workflow_id: params[:id]
    }
  end
end 

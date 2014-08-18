class Api::V1::WorkflowsController < Api::ApiController
  doorkeeper_for :update, :create, :delete, scopes: [:project]

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

  def create
    workflow = Workflow.new creation_params
    workflow.save!
    json_api_render( 201,
                     WorkflowSerializer.resource(workflow),
                     api_workflow_url(workflow) )
  end

  def destroy
    workflow.destroy!
    deleted_resource_response
  end

  alias_method :workflow, :controlled_resource

  access_control_for :create, :update, :destroy, resource_class: Workflow
  
  private

  def creation_params
    params.require(:workflow)
      .permit(:name, :project_id, :pairwise, :grouped, :prioritized, :primary_language)
      .merge tasks: params[:workflow][:tasks]
  end

  def load_cellect
    return unless api_user
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

class Api::V1::ClassificationsController < Api::ApiController
  doorkeeper_for :show, :index, :update, :delete, scopes: [:classifications]

  def show
    render json_api: ClassificationsSerializer.resource(params)
  end

  def index
    render json_api: ClassificationsSerializer.page(params)
  end

  def update

  end

  def create
    update_cellect if current_resource_owner
    render json_api: {}, status: 204
  end

  def destroy

  end

  private

  def update_cellect
    Cellect::Client.connection.add_seen(params[:subject_id], **cellect_params)
  end

  def cellect_params
    {
      user_id: current_resource_owner.id,
      workflow_id: params[:workflow_id],
      host: cellect_host(params[:workflow_id])
    }
  end
end 

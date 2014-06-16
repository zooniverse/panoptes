class Api::V1::WorkflowsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json_api: WorkflowSerializer.resource(params)
  end

  def index
    render json_api: WorkflowSerializer.resource(params)
  end

  def update

  end

  def create

  end

  def delete

  end
end 

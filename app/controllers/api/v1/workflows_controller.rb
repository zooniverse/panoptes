class Api::V1::WorkflowsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json: WorkflowSerializer.resource(params), content_type: api_content
  end

  def index
    render json: WorkflowSerializer.resource(params), content_type: api_content
  end

  def update

  end

  def create

  end

  def delete

  end
end 

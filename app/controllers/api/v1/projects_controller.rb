class Api::V1::ProjectsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json: ProjectsSerializer.resource(params), content_type: api_content
  end

  def index
    render json: ProjectsSerializer.page(params), content_type: api_content
  end

  def update
    # TODO: implement JSON-Patch or find a gem that does
  end

  def create

  end

  def delete
  
  end
end 

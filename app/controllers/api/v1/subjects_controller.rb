class Api::V1::SubjectsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json: SubjectSerializer.page(params), content_type: api_content
  end

  def index
    render json: SubjectSerializer.resource(params), content_type: api_content
  end

  def update

  end

  def create

  end

  def delete

  end
end 

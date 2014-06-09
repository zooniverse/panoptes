class Api::V1::SubjectSetsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json: SubjectSetSerializer.resource(params), content_type: api_content
  end

  def index
    render json: SubjectSetSerializer.page(params), content_type: api_content
  end

  def update

  end

  def create

  end

  def delete

  end
end 

class Api::V1::SubjectsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json_api: SubjectSerializer.page(params)
  end

  def index
    render json_api: SubjectSerializer.resource(params)
  end

  def update

  end

  def create

  end

  def delete

  end
end 

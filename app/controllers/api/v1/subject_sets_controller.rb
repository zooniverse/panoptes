class Api::V1::SubjectSetsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json_api: SubjectSetSerializer.resource(params)
  end

  def index
    render json_api: SubjectSetSerializer.page(params)
  end

  def update

  end

  def create

  end

  def delete

  end
end 

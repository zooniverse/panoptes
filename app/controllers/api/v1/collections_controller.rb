class Api::V1::CollectionsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json_api: CollectionsSerializer.resource(params)

  end

  def index
    render json_api: CollectionsSerializer.resource(params)
  end

  def update

  end

  def create

  end

  def delete

  end
end 

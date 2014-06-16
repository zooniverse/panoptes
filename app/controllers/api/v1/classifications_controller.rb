class Api::V1::ClassificationsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json_api: ClassificationsSerializer.resource(params)
  end

  def index
    render json_api: ClassificationsSerializer.page(params)
  end

  def update

  end

  def create

  end

  def delete

  end
end 

class Api::V1::ClassificationsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json: ClassificationsSerializer.resource(params), content_type: api_content
  end

  def index
    render json: ClassificationsSerializer.page(params), content_type: api_content
  end

  def update

  end

  def create

  end

  def delete

  end
end 

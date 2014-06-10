class Api::V1::CollectionsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json: CollectionsSerializer.resource(params), content_type: api_content

  end

  def index
    render json: CollectionsSerializer.resource(params), content_type: api_content
  end

  def update

  end

  def create

  end

  def delete

  end
end 

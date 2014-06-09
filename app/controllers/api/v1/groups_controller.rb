class Api::V1::GroupsController < Api::ApiController
  doorkeeper_for :all

  def show
    render json: GroupsSerailizer.resource(params), content_type: api_content
  end

  def index
    render json: GroupsSerailizer.page(params), content_type: api_content
  end

  def update

  end

  def create

  end

  def delete

  end
end 

class Api::V1::UsersController < Api::ApiController
  doorkeeper_for :all

  def show
    render json: current_resource_owner.to_json, content_type: api_content
  end
end

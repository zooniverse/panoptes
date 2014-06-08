class Api::V1::UsersController < Api::ApiController
  def index
    render json: UserSerializer.page(params), content_type: api_content
  end

  def show
    render json: UserSerializer.resource(params), content_type: api_content
  end

  def me
    render json: UserSerializer.single(current_resource_owner), content_type: api_content
  end

  def update
    # TODO: implement JSON-Patch or find a gem that does 
  end
end

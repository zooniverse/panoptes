class Api::V1::UsersController < Api::ApiController
  doorkeeper_for :all

  def index
    render json: UserSerializer.page(params), content_type: api_content
  end

  def show
    render json: UserSerializer.resource(params), content_type: api_content
  end

  def me
    render json: UserSerializer.resource(id: current_resource_owner.id), content_type: api_content
  end

  def update
    response_status, response_body = begin
      user = User.find(params[:id])
      user.update!(request_update_attributes(user))
      [ 200, UserSerializer.resource(user) ]
    rescue PatchResourceError, ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      status = e.is_a?(ActiveRecord::RecordNotFound) ? 404 : 400
      [ status, e.message.to_json ]
    end
    render status: response_status, json: response_body, content_type: api_content
  end

  def destroy
    user = User.find(params[:id])
    UserInfoScrubber.scrub_personal_info!(user)
    Activation.disable_instances!([ user ] | user.projects | user.collections | user.memberships)
    deleted_resource_response
  end
end

class Api::V1::UsersController < Api::ApiController
  doorkeeper_for :index, :me, :show, scopes: [:public]
  doorkeeper_for :update, :destroy, scopes: [:user]

  after_action :verify_authorized, except: :index

  def index
    render json: UserSerializer.page(params), content_type: api_content
  end

  def show
    user = User.find(params[:id])
    authorize user, :read?
    render json: UserSerializer.resource(user), content_type: api_content
  end

  def me
    authorize current_resource_owner, :read?
    render json: UserSerializer.resource(current_resource_owner), content_type: api_content
  end

  def update
    response_status, response_body = begin
      user = User.find(params[:id])
      authorize user
      user.update!(request_update_attributes(user))
      [ 200, UserSerializer.resource(user) ]
    rescue PatchResourceError, ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
      status = e.is_a?(ActiveRecord::RecordNotFound) ? 404 : 400
      [ status, e.message.to_json ]
    end
    render status: response_status, json: response_body, content_type: api_content
  end

  def destroy
    p "HERE"
    user = User.find(params[:id])
    authorize user, :delete?
    UserInfoScrubber.scrub_personal_info!(user)
    Activation.disable_instances!([ user ] | user.projects | user.collections | user.memberships)
    deleted_resource_response
  end
end

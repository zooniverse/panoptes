class Api::V1::UsersController < Api::ApiController
  doorkeeper_for :index, :me, :show, scopes: [:public]
  doorkeeper_for :update, :destroy, scopes: [:user]

  after_action :verify_authorized, except: :index

  def index
    render json_api: UserSerializer.page(params)
  end

  def show
    user = User.find(params[:id])
    authorize user, :read?
    render json_api: UserSerializer.resource(user)
  end

  def me
    authorize current_resource_owner, :read?
    render json_api: UserSerializer.resource(current_resource_owner)
  end

  def update
    response_status, response = begin
      user = User.find(params[:id])
      authorize user
      user.update!(request_update_attributes(user))
      [ :ok, UserSerializer.resource(user) ]
    rescue PatchResourceError, ActiveRecord::RecordInvalid => e
      [ :bad_request, e ]
    end
    render status: response_status, json_api: response
  end

  def destroy
    user = User.find(params[:id])
    authorize user, :destroy?
    UserInfoScrubber.scrub_personal_info!(user)
    Activation.disable_instances!([ user ] | user.projects | user.collections | user.memberships)
    deleted_resource_response
  end
end

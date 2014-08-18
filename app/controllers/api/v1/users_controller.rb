class Api::V1::UsersController < Api::ApiController
  doorkeeper_for :index, :me, :show, scopes: [:public]
  doorkeeper_for :update, :destroy, scopes: [:user]

  def index
    render json_api: UserSerializer.page(params)
  end

  def show
    render json_api: UserSerializer.resource(params)
  end

  def me
    render json_api: UserSerializer.resource(current_resource_owner)
  end

  def update
    response_status, response = begin
      user.update!(request_update_attributes(user))
      [ :ok, UserSerializer.resource(user) ]
    rescue Api::PatchResourceError, ActiveRecord::RecordInvalid => e
      [ :bad_request, e ]
    end
    render status: response_status, json_api: response
  end

  def destroy
    sign_out if current_user && (current_user == user)
    UserInfoScrubber.scrub_personal_info!(user)
    Activation.disable_instances!([ user ] |
                                  user.projects |
                                  user.collections |
                                  user.memberships)
    revoke_doorkeeper_request_token!
    deleted_resource_response
  end

  alias_method :user, :controlled_resource

  access_control_for :update, :destroy, resource_class: User
end

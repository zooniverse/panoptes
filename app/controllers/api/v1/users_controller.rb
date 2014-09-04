class Api::V1::UsersController < Api::ApiController
  include Deactivatable
  
  doorkeeper_for :index, :me, :show, scopes: [:public]
  doorkeeper_for :update, :destroy, scopes: [:user]
  access_control_for :update, :destroy, resource_class: User

  alias_method :user, :controlled_resource

  def index
    render json_api: page_serializer(params)
  end

  def show
    render json_api: resource_serializer(params)
  end

  def me
    render json_api: resource_serializer(current_resource_owner)
  end

  def destroy
    sign_out if current_user && (current_user == user)
    revoke_doorkeeper_request_token!
    UserInfoScrubber.scrub_personal_info!(user)
    super
  end

  private

  def to_disable
    [ user ] |
      user.projects |
      user.collections |
      user.memberships
  end

  def resource_serializer(*args)
    UserSerializer.resource(*args)
  end

  def page_serializer(*args)
    UserSerializer.page(*args)
  end

  def permitted_update_attributes
    params.require(:users).permit(:display_name, :email, :credited_name)
  end


  def revoke_doorkeeper_request_token!
    token = Doorkeeper.authenticate(request)
    token.revoke
  end
end

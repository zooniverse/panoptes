class Api::V1::UsersController < Api::ApiController
  include JsonApiController 
  
  doorkeeper_for :index, :me, :show, scopes: [:public]
  doorkeeper_for :update, :destroy, scopes: [:user]
  access_control_for :update, :destroy, resource_class: User

  resource_actions :deactivate, :update, :index, :show

  allowed_params :update, :display_name, :email, :credited_name

  alias_method :user, :controlled_resource
  
  def me
    render json_api: serializer.resource(current_resource_owner)
  end

  def destroy
    sign_out if current_user && (current_user == user)
    revoke_doorkeeper_request_token!
    UserInfoScrubber.scrub_personal_info!(user)
    super
  end

  private

  def visible_scope
    User.all
  end

  def to_disable
    [ user ] |
      user.projects |
      user.collections |
      user.memberships
  end

  def serializer
    UserSerializer
  end

  def revoke_doorkeeper_request_token!
    token = Doorkeeper.authenticate(request)
    token.revoke
  end
end

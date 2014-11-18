class Api::V1::UsersController < Api::ApiController
  include JsonApiController 
  
  doorkeeper_for :me, :show, scopes: [:public]
  doorkeeper_for :update, :destroy, scopes: [:user]
  resource_actions :deactivate, :update, :index, :show
  schema_type :strong_params

  allowed_params :update, :display_name, :email, :credited_name

  alias_method :user, :controlled_resource
  
  def me
    render json_api: serializer.resource(current_resource_owner, nil, context)
  end

  def destroy
    sign_out_current_user!
    revoke_doorkeeper_request_token!
    UserInfoScrubber.scrub_personal_info!(user)
    super
  end

  private

  def context
    { requester: api_user }
  end

  def sign_out_current_user!
    sign_out if current_user && (current_user == user)
  end

  def visible_scope
    User.all
  end

  def to_disable
    [ user ] |
      user.projects |
      user.collections |
      user.memberships
  end

  def revoke_doorkeeper_request_token!
    token = Doorkeeper.authenticate(request)
    token.revoke
  end
end

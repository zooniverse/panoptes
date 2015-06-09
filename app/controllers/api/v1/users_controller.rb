class Api::V1::UsersController < Api::ApiController
  include Recents

  doorkeeper_for :me, scopes: [:public]
  doorkeeper_for :update, :destroy, scopes: [:user]
  resource_actions :deactivate, :update, :index, :show

  schema_type :strong_params

  allowed_params :update, :login, :display_name, :email, :credited_name,
   :global_email_communication, :project_email_communication,
   :beta_email_communication

  alias_method :user, :controlled_resource

  def me
    if stale?(last_modified: current_resource_owner.updated_at)
      render json_api: serializer.resource({},
                                           resource_scope(current_resource_owner),
                                           context)
    end
  end

  def update
    super do |user|
      case
      when user.global_email_communication_changed?
        if user.global_email_communication
          SubscribeWorker.perform_async(user.email, user.display_name)
        else
          UnsubscribeWorker.perform_async(user.email)
        end
      when user.email_change # I cannot figure out why but user.email_changed? returns true when no change has happened
        if user.global_email_communication
          SubscribeWorker.perform_async(user.email, user.display_name)
          UnsubscribeWorker.perform_async(user.changes[:email].first)
        end
      end
    end
  end

  def index
    if display_name = params.delete(:display_name)
      @controlled_resources = controlled_resources.where('"users"."display_name" ILIKE ?', display_name + '%')
    elsif slug = params.delete(:slug)
      @controlled_resources = controlled_resources.joins(:user_groups).where(user_groups: {slug: slug})
    end
    super
  end

  def destroy
    sign_out_current_user!
    revoke_doorkeeper_request_token!
    UnsubscribeWorker.perform_async(user.email)
    UserInfoScrubber.scrub_personal_info!(user)
    super
  end

  private

  def context
    { requester: api_user, include_firebase_token: true }
  end

  def sign_out_current_user!
    sign_out if current_user && (current_user == user)
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

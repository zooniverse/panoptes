class Api::V1::UsersController < Api::ApiController
  include Recents
  include IndexSearch
  include AdminAllowed

  require_authentication :me, scopes: [:public]
  require_authentication :update, :destroy, scopes: [:user]
  resource_actions :deactivate, :update, :index, :show

  schema_type :strong_params

  allowed_params :update, :login, :display_name, :email, :credited_name,
   :global_email_communication, :project_email_communication,
   :beta_email_communication, :subject_limit, :upload_whitelist

  alias_method :user, :controlled_resource

  search_by do |name, query|
    search_names = name.join(" ").downcase
    login_search = query.where("lower(login) = ?", search_names)

    if login_search.exists?
      login_search
    else
      names = search_names.gsub(/[^#{ ::User::ALLOWED_LOGIN_CHARACTERS }]/, '')
      if names.present? && names.length >= 3
        query.full_search_login(names)
      else
        User.none
      end
    end
  end

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
          SubscribeWorker.perform_async(user.email)
        else
          UnsubscribeWorker.perform_async(user.email)
        end
      when user.email_changed?
        if user.global_email_communication
          SubscribeWorker.perform_async(user.email)
          UnsubscribeWorker.perform_async(user.changes[:email].first)
        end
      end
    end
  end

  def index
    if logins = params.delete(:login).try(:split, ',').try(:map, &:downcase)
      @controlled_resources = controlled_resources.where(User.arel_table[:login].lower.in(logins))
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

  def build_update_hash(update_params, id)
    admin_allowed(update_params, :subject_limit, :upload_whitelist)
    super
  end

  private

  def context
    { requester: api_user }
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

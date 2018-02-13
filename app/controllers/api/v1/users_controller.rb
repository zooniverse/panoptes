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
   :beta_email_communication, :languages, :subject_limit, :upload_whitelist,
   :banned, :valid_email

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
    [].tap do |update_email_user_ids|

      super do |user|
        unless user.project_email_communication
          unsubscribe_all_project_emails(user)
        end

        if user.email_changed?
          update_email_user_ids << user.id
        end
      end

      update_email_user_ids.each do |user_id|
        UserInfoChangedMailerWorker.perform_async(user_id, "email")
      end
    end
  end

  def index
    if api_user.is_admin? and emails = params.delete(:email).try(:split, ',').try(:map, &:downcase)
      @controlled_resources = controlled_resources.where(User.arel_table[:email].lower.in(logins))
    elsif logins = params.delete(:login).try(:split, ',').try(:map, &:downcase)
      @controlled_resources = controlled_resources.where(User.arel_table[:login].lower.in(logins))
    end
    super
  end

  def destroy
    sign_out_current_user!
    revoke_doorkeeper_request_token!
    UserInfoScrubber.scrub_personal_info!(user)
    super
  end

  def build_update_hash(update_params, id)
    admin_allowed(update_params, :subject_limit, :upload_whitelist, :banned,
                  :valid_email)
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

  def unsubscribe_all_project_emails(user)
    UserProjectPreference
     .where(user_id: user.id)
     .update_all(email_communication: false)
  end
end

Doorkeeper.configure do
  orm :active_record

  enable_application_owner :confirmation => true

  default_scopes  :public
  optional_scopes :user, :project, :group, :collection

  realm "Panoptes"

  resource_owner_authenticator do
    u = current_user || warden.authenticate!(scope: :user)
    u if !u.disabled?
  end

  resource_owner_from_credentials do
    if u = User.find_for_database_authentication(login: params[:login])
      valid_non_disabled_user = u.valid_password?(params[:password]) && !u.disabled?
    else
      u = current_user
      valid_non_disabled_user = !u.blank? && !u.disabled?
    end
    u if valid_non_disabled_user
  end
end

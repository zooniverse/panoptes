module Doorkeeper
  module PanoptesScopes
    def self.optional
      %i(user project group collection classification subject medium)
    end
  end
end

Doorkeeper.configure do
  orm :active_record

  use_refresh_token

  enable_application_owner :confirmation => true

  default_scopes  :public
  optional_scopes *Doorkeeper::PanoptesScopes.optional

  realm "Panoptes"

  grant_flows ["authorization_code", "client_credentials", "implicit", "password"]

  resource_owner_authenticator do
    u = current_user || warden.authenticate!(scope: :user)
    u if !u.disabled?
  end

  resource_owner_from_credentials do
    if params[:login] && u = User.find_for_database_authentication(login: params[:login])
      valid_non_disabled_user = u.valid_password?(params[:password]) && !u.disabled?
    else
      u = current_user
      valid_non_disabled_user = !u.blank? && !u.disabled?
    end
    u if valid_non_disabled_user
  end

  admin_authenticator do |routes|
    if u = current_user
      u.admin ? u :
        (render file: "#{Rails.root}/public/403.html", status: 403, layout: false)
    else
      redirect_to(new_user_session_path)
    end
  end
end

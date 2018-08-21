module Doorkeeper
  module Panoptes
    module Scopes
      def self.optional
        %i(user project group collection classification subject medium organization translation)
      end
    end

    module Host
      ALLOWED_INSECURE_HOSTS = %w(localhost local.zooniverse.org).freeze

      def self.force_secure_scheme?(host)
        !ALLOWED_INSECURE_HOSTS.include?(host)
      end
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

  access_token_generator "Doorkeeper::JWT"

  # Remove the scheme check
  # once Doorkeeper v5 is released (no backport fix)
  # https://github.com/doorkeeper-gem/doorkeeper/issues/1091
  force_ssl_in_redirect_uri do |uri|
    if uri.scheme == 'https'
      false
    else
      Doorkeeper::Panoptes::Host.force_secure_scheme?(uri.host)
    end
  end

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

Doorkeeper::JWT.configure do
  token_payload do |opts|
    user = User.find(opts[:resource_owner_id])

    {
      data: {
        id: user.id,
        login: user.login,
        dname: user.display_name,
        scope: opts[:scopes].to_a,
        admin: user.is_admin?
      },
      exp: Time.now.to_i + opts[:expires_in],
      iss: "pan-#{Rails.env.to_s[0..3]}",

      # RNG is not an official JWT claim.
      # Needed so that JWT token is unique even when making multiple requests at the same time.
      # Shorter than using the standard 'jti' claim with a UUID in it (saves about 40 chars in
      # the resulting Base64-string).
      rng: SecureRandom.hex(2)
    }
  end

  use_application_secret false

  # Generate these with
  # rsa_private = OpenSSL::PKey::RSA.generate 4096
  # rsa_public = rsa_private.public_key
  secret_key_path Rails.root.join("config", "doorkeeper-jwt-#{Rails.env}.pem")

  # Sign using RSA SHA-512
  encryption_method :rs512
end

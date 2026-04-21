# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Doorkeeper::OpenidConnect.configure do
  issuer do |_resource_owner, _application|
    if Rails.env.production?
      'https://panoptes.zooniverse.org'
    elsif Rails.env.staging? # rubocop:disable Rails/UnknownEnv
      'https://panoptes-staging.zooniverse.org'
    else
      'http://localhost:3000'
    end
  end

  # Use the same RSA key that Doorkeeper::JWT uses for signing access tokens.
  signing_key lambda {
    key_path = Rails.root.join('config', 'keys', "doorkeeper-jwt-#{Rails.env}.pem")
    File.read(key_path)
  }

  signing_algorithm :rs512

  # Resolve the resource owner (User) from a Doorkeeper access token.
  resource_owner_from_access_token do |access_token|
    User.find_by(id: access_token.resource_owner_id)
  end

  # Return the time the user last authenticated. Devise's current_sign_in_at tracks this.
  auth_time_from_resource_owner do |resource_owner|
    resource_owner.current_sign_in_at&.to_i
  end

  # Re-authentication handler. For the password grant flow used in development,
  # the user is always freshly authenticated so we return them directly.
  reauthenticate_resource_owner do |resource_owner, _return_to|
    resource_owner
  end

  # OIDC subject identifier - unique, stable user ID.
  subject do |resource_owner, _application|
    resource_owner.id
  end

  subject_types_supported %i[public]

  claims do
    claim :login, scope: :openid do |resource_owner, _scopes, _access_token|
      resource_owner.login
    end

    claim :name, scope: :openid do |resource_owner, _scopes, _access_token|
      resource_owner.display_name
    end

    claim :credited_name, scope: :openid do |resource_owner, _scopes, _access_token|
      resource_owner.credited_name
    end

    claim :email, scope: :openid, response: %i[id_token user_info] do |resource_owner, _scopes, _access_token|
      resource_owner.email
    end

    claim :email_verified, scope: :openid, response: %i[id_token user_info] do |resource_owner, _scopes, _access_token|
      resource_owner.confirmed_at.present?
    end

    claim :admin, scope: :openid do |resource_owner, _scopes, _access_token|
      resource_owner.admin?
    end

    claim :created_at, scope: :openid do |resource_owner, _scopes, _access_token|
      resource_owner.created_at.to_i
    end

    claim :zooniverse_id, scope: :openid do |resource_owner, _scopes, _access_token|
      resource_owner.zooniverse_id
    end
  end
end
# rubocop:enable Metrics/BlockLength

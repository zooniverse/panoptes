require 'doorkeeper/orm/active_record/application'

Doorkeeper::Application.class_eval do
  enum trust_level: [:insecure, :secure, :first_party]

  def scopes
    scope = default_scope.blank? ? 'public' : default_scope
    Doorkeeper::OAuth::Scopes.from_array(scope)
  end

  def allowed_grants
    if secure?
      %w(client_credentials authorization_code refresh_token)
    elsif insecure?
      %w(refresh_token)
    else
      %w(client_credentials authorization_code password refresh_token)
    end
  end

  def allowed_authorizations
    if secure? || first_party?
      %w(token code)
    else
      %w(token)
    end
  end
end

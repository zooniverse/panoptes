require 'doorkeeper/models/application'

Doorkeeper::Application.class_eval do
  enum trust_level: [:insecure, :secure, :first_party]

  def scopes
    Doorkeeper::OAuth::Scopes.from_array(max_scope)
  end

  def allowed_grants
    if secure?
      %w(client_credentials authorization_code)
    elsif insecure?
      []
    else
      %w(client_credentails authorization_code password)
    end
  end

  def allowed_auth_requests
    if secure? || first_party?
      %w(token code)
    else
      %w(token)
    end
  end
end

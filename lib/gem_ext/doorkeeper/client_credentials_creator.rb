require 'doorkeeper/oauth/client_credentials/creator'

Doorkeeper::OAuth::ClientCredentialsRequest::Creator.class_eval do
  def call(client, scopes, attributes = {})
    Doorkeeper::AccessToken.create(attributes.merge(
      resource_owner_id: client.application.owner_id,
      application_id: client.id,
      scopes: scopes.to_s
    ))
  end
end

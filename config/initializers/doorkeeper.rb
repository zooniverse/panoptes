Doorkeeper.configure do
  orm :active_record

  resource_owner_authenticator do
    current_user || warden.authenticate!(scope: :user)
  end

  enable_application_owner :confirmation => true

  default_scopes  :public
  optional_scopes :user, :project, :group, :collection

  realm "Panoptes"
end

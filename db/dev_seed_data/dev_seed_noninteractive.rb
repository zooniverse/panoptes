# frozen_string_literal: true

exit unless Rails.env.development?

# Non-interactive version of dev_seed_data.rb for automated setup.
# Uses a default password for the local admin user.

DEFAULT_PASSWORD = 'password1234'

Rails.logger.info "\n=== Panoptes Local Dev Setup (non-interactive) ==="

# Setup admin user
attrs = {
  admin: true,
  password: DEFAULT_PASSWORD,
  login: 'zooniverse_admin',
  email: 'no-reply@zooniverse.org'
}
admin = User.where(login: 'zooniverse_admin').first_or_create(attrs, &:build_identity_group)

if admin.persisted?
  Rails.logger.info "Admin user: #{admin.login} (email: #{admin.email})"
  Rails.logger.info "Password:   #{DEFAULT_PASSWORD}"
else
  Rails.logger.info "ERROR: Failed to create admin user: #{admin.errors.full_messages.join(', ')}"
  exit 1
end

# Setup Doorkeeper first-party OAuth application with openid scope
app = Doorkeeper::Application.where(name: 'DevAppClient').first_or_create do |da|
  da.owner = admin
  da.name = 'DevAppClient'
  da.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
  da.trust_level = 2
  da.confidential = false
  scopes = %i[public openid] | Doorkeeper::Panoptes::Scopes.optional
  da.default_scope = scopes.map(&:to_s)
end

if app.persisted?
  Rails.logger.info "OAuth app:  #{app.name}"
  Rails.logger.info "Client ID:  #{app.uid}"
  Rails.logger.info "\nAccess at: http://localhost:3000/oauth/applications"
else
  Rails.logger.info "ERROR: Failed to create OAuth app: #{app.errors.full_messages.join(', ')}"
  exit 1
end

Rails.logger.info "\n=== Setup complete ==="

# Be sure to restart your server when you modify this file.

domain =
  if %w(production staging).include?(Rails.env)
    # allow zooniverse.org subdomains for staging & production
    '.zooniverse.org'
  else
    # allow all subdomains for dev & test
    :all
  end

Rails.application.config.session_store :cookie_store,
    key: '_Panoptes_session',
    domain: domain

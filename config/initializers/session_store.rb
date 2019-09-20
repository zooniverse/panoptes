# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store,
    key: '_Panoptes_session',
    domain: {
      production: '.zooniverse.org',
      staging: '.zooniverse.org'
    }.fetch(Rails.env.to_sym, :all)

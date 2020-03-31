Devise.setup do |config|
  config.mailer_sender = 'no-reply@zooniverse.org'

  require 'devise/orm/active_record'

  config.authentication_keys = [ :login ]
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 10
  config.reconfirmable = true
  config.password_length = 8..128
  config.reset_password_within = 6.hours
  config.paranoid = true
  config.sign_out_via = :delete

  # MAILER
  require 'devise_mailer/background_mailer'
  config.mailer = "Devise::BackgroundMailer"

  # OMNIAUTH

  def load_social_config
    {
      facebook: {
        app_id: ENV['SOCIAL_FACEBOOK_APP_ID'],
        app_secret: ENV['SOCIAL_FACEBOOK_APP_SECRET'],
        scope: ENV['SOCIAL_FACEBOOK_SCOPE']
      },
      google_oauth2: {
        app_id: ENV['SOCIAL_GOOGLE_APP_ID'],
        app_secret: ENV['SOCIAL_GOOGLE_APP_SECRET'],
        scope: ENV['SOCIAL_GOOGLE_SCOPE'],
        request_visible_actions: ENV['SOCIAL_GOOGLE_REQUEST_VISIBLE_ACTIONS']
      }
    }
  end

  def social_config
    @social_config ||= load_social_config
  end

  def omniauth_config_for(config, providers: provider)
    providers.each do |provider|
      conf = social_config[provider].symbolize_keys
      config.omniauth provider, conf.delete(:app_id), conf.delete(:app_secret), **conf
    end
  end

  omniauth_config_for(config, providers: [:facebook, :google_oauth2])
end

module Panoptes
  def self.frontend_url
    ENV.fetch('REDIRECTS_BASE', 'http://localhost:2727')
  end

  def self.password_reset_redirect
    "#{frontend_url}#{ENV.fetch('REDIRECTS_PASSWORD_RESET', '/#/reset-password')}"
  end

  def self.unsubscribe_redirect
    "#{frontend_url}#{ENV.fetch('REDIRECTS_UNSUBSCRIBE', '/#/unsubscribe')}"
  end
end

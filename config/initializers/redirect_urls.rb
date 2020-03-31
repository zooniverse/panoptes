module Panoptes
  def self.frontend_configuration
    @frontend_conf ||= {
      base: ENV['REDIRECTS_BASE'] || 'http://localhost:2727',
      password_reset: ENV['REDIRECTS_PASSWORD_RESET'] || '/#/reset-password',
      unsubscribe: ENV['REDIRECTS_UNSUBSCRIBE'] || '/#/unsubscribe'
    }
  end

  def self.frontend_url
    frontend_configuration[:base]
  end

  def self.password_reset_redirect
    if reset = frontend_configuration[:password_reset]
      "#{frontend_url}#{reset}"
    end
  end

  def self.unsubscribe_redirect
    if unsubscribe = frontend_configuration[:unsubscribe]
      "#{frontend_url}#{unsubscribe}"
    end
  end
end

Panoptes.frontend_configuration

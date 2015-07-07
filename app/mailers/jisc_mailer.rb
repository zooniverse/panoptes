class JiscMailer < ApplicationMailer
  layout 'jisc_mail'

  JISC_MAIL_ADDRESS = "listserv@jiscmail.ac.uk"

  def subscribe(email)
    check_config
    @email = email
    mail(to: JISC_MAIL_ADDRESS)
  end

  def unsubscribe(email)
    check_config
    @email = email
    mail(to: JISC_MAIL_ADDRESS)
  end

  def check_config
    unless ::Panoptes.jisc_mail_config.has_key?(:password)
      raise StandardError, "JISC Mail password required"
    end
  end
end

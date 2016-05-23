class UserInfoChangedMailer < ApplicationMailer
  layout false

  SITE_NAME = "the Zooniverse"

  def user_info_changed(user, info)
    @user = user
    @email_to = user.email

    case info
    when :email
      subject = "Your Zooniverse email address has been changed"
      template = "email_changed"
    when :password
      subject = "Your Zooniverse password has been changed"
      template = "password_changed"
    end

    mail(to: @email_to, subject: subject, :template_name => template )
  end
end

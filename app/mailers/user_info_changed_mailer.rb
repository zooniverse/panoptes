class UserInfoChangedMailer < ApplicationMailer
  layout false

  def user_info_changed(user, info, previous_email=nil)
    @user = user
    @recipient_emails = [user.email]
    @recipient_emails << previous_email if previous_email.present? && info == "email"

    case info
    when "email"
      subject = "Your Zooniverse email address has been changed"
      template = "email_changed"
    when "password"
      subject = "Your Zooniverse password has been changed"
      template = "password_changed"
    end

    mail(to: @recipient_emails, subject: 'Limited subject', :template_name => template )
  end
end

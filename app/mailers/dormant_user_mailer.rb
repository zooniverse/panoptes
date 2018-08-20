class DormantUserMailer < ApplicationMailer
  layout false

  DEFAULT_SUBJECT = "Come back to the Zooniverse"

  def email_dormant_user(user)
    @user = user
    @email_to = user.email
    mail(to: @email_to, subject: DEFAULT_SUBJECT)
  end

end

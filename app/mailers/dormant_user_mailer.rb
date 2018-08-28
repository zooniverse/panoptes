class DormantUserMailer < ApplicationMailer
  layout false

  DEFAULT_SUBJECT = "Come back to the Zooniverse".freeze

  def email_dormant_user(user)
    @user = user
    @email_to = user.email
    @last_project= UserProjectPreference.where(user_id: user.id).first
    mail(to: @email_to, subject: DEFAULT_SUBJECT)
  end

end

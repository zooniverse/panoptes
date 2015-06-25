class UserWelcomeMailer < ApplicationMailer
  layout false

  SITE_NAME = "the Zooniverse"
  DEFAULT_SUBJECT = "Welcome to #{SITE_NAME}! Your Account & What’s Next"

  def welcome_user(user, project_name=nil)
    @user = user
    @email_to = user.email
    @welcome_location = project_name ? project_name : SITE_NAME
    mail(to: @email_to, subject: DEFAULT_SUBJECT)
  end
end

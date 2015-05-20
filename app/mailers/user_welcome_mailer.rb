class UserWelcomeMailer < ApplicationMailer

  DEFAULT_SUBJECT = "Welcome to the Zooniverse!"

  def welcome_user(user)
    @user = user
    @email_to = user.email
    mail(to: @email_to, subject: DEFAULT_SUBJECT)
  end

  def project_welcome_user(user, project)
    @user = user
    @project = project
    @email_to = user.email
    mail(to: @email_to, subject: DEFAULT_SUBJECT)
  end
end

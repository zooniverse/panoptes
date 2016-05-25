class UserAddedToProjectMailer < ApplicationMailer
  layout false

  SITE_NAME = "the Zooniverse"
  DEFAULT_SUBJECT = "You've been added to a new Zooniverse project!"

  def added_to_project(user, project, roles)
    @user = user
    @project = project
    @roles = roles
    @email_to = user.email
    mail(to: @email_to, subject: DEFAULT_SUBJECT)
  end
end

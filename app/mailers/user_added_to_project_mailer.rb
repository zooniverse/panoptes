class UserAddedToProjectMailer < ApplicationMailer
  layout false

  def added_to_project(user, project, roles)
    @user = user
    @project = project
    @roles = roles
    @email_to = user.email
    mail(to: @email_to, subject: "You've been added to a new Zooniverse project!")
  end
end

class ClassificationDataMailer < ApplicationMailer

  def classification_data(project, data_url)
    @project = project
    @email_to = User.joins(user_groups: :access_control_lists)
      .where(access_control_lists: { resource_type: "Project", resource_id: project.id })
      .where.overlap(access_control_lists: { roles: ["owner", "collaborator"]})
      .pluck(:email)
    @url = data_url
    mail(to: @email_to, subject: "Classification Data is Ready")
  end

end

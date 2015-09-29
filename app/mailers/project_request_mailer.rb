class ProjectRequestMailer < ApplicationMailer

  def project_request(type, project_id)
    @type = type
    project = Project.find(project_id)
    @owner = project.owner.display_name
    @name = project.primary_content.title
    @url = "#{Panoptes.project_request.base_url}/projects/#{project.slug}"
    emails = [project.owner.email].concat(Panoptes.project_request.recipients)
    mail(to: emails, subject: "Project #{@type} update")
  end
end

class ProjectRequestMailer < ApplicationMailer

  def project_request(type, project_id)
    @type = type
    project = Project.find(project_id)
    @owner = project.owner.display_name
    @name = project.display_name
    @url = "#{Panoptes.project_request.base_url}/projects/#{project.slug}"
    mail(
      to: [project.owner.email].concat(Panoptes.project_request.recipients),
      bcc: Panoptes.project_request.bcc,
      subject: "Project #{@type} update"
    )
  end
end

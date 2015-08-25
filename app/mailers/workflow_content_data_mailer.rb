class WorkflowContentDataMailer < ApplicationMailer

  def workflow_content_data(project, data_url, emails)
    @project = project
    @url = data_url
    mail(to: emails, subject: "Workflow Content Data is Ready")
  end
end

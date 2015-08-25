class WorkflowDataMailer < ApplicationMailer

  def workflow_data(project, data_url, emails)
    @project = project
    @url = data_url
    mail(to: emails, subject: "Workflow Data is Ready")
  end
end

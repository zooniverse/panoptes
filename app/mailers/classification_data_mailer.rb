class ClassificationDataMailer < ApplicationMailer

  def classification_data(project, data_url, emails)
    @project = project
    @url = data_url
    mail(to: emails, subject: "Classification Data is Ready")
  end

end

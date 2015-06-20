class SubjectDataMailer < ApplicationMailer
  def subject_data(project, data_url, emails)
    @project = project
    @url = data_url
    mail(to: emails, subject: "Subject Data is Ready")
  end
end

class ClassificationDataMailer < ApplicationMailer

  def classification_data(resource, data_url, emails)
    @resource = resource
    @url = data_url
    mail(to: emails, subject: "Classification Data is Ready")
  end

end

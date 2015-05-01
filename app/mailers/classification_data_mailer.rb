class ClassificationDataMailer < ApplicationMailer

  def classification_data(project, data_url)
    @project = project
    @owner = project.owner
    @url = data_url
    return if @owner.is_a?(UserGroup)
    mail(to: @owner.email, subject: "Classification Data is Ready")
  end

end

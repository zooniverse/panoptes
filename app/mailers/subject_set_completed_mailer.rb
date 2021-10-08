class SubjectSetCompletedMailer < ApplicationMailer
  layout false

  def notify_project_team(project, subject_set)
    @project = project
    @subject_set_id = subject_set.id
    @subject_set_name = subject_set.display_name
    @project_lab_data_export_url = lab_export_url(project.id)
    @email_to = project.communication_emails

    subject = "Your Zooniverse project - a subject set has been completed"

    mail(to: @email_to, subject: subject)
  end

  private

  def lab_export_url(project_id)
    "#{Panoptes.frontend_url}/lab/#{project_id}/data-exports"
  end
end

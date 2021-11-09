# frozen_string_literal: true

class SubjectSetCompletedMailer < ApplicationMailer
  layout false

  def notify_project_team(project, subject_set)
    lab_url_prefix = "#{Panoptes.frontend_url}/lab/#{project.id}"
    @subject_set_lab_url = "#{lab_url_prefix}/subject-sets/#{subject_set.id}"
    @subject_set_name = subject_set.display_name
    @project_lab_data_export_url = "#{lab_url_prefix}/data-exports"
    @email_to = project.communication_emails

    subject = 'Your Zooniverse project - subject set has completed'

    mail(to: @email_to, subject: subject)
  end
end

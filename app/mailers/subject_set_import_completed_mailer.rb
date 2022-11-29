# frozen_string_literal: true

class SubjectSetImportCompletedMailer < ApplicationMailer
  layout false

  def notify_project_team(project, subject_set_import)
    subject_set = subject_set_import.subject_set
    lab_url_prefix = "#{Panoptes.frontend_url}/lab/#{project.id}"
    @subject_set_lab_url = "#{lab_url_prefix}/subject-sets/#{subject_set.id}"
    @subject_set_name = subject_set.display_name
    @email_to = project.communication_emails
    @no_errors = subject_set_import.failed_count.zero?

    import_status = @no_errors ? 'success' : 'completed with errors'

    subject = "Your Zooniverse project - subject set import #{import_status}"

    mail(to: @email_to, subject: subject)
  end
end

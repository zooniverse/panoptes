class InatImportCompletedMailer < ApplicationMailer
  layout false

  def inat_import_complete(ss_import)
    @user = User.find(ss_import.user_id)
    @email_to = @user.email
    @imported_count = ss_import.imported_count
    project_id = ss_import.subject_set.project_id

    lab_url_prefix = "#{Panoptes.frontend_url}/lab/#{project_id}"
    @subject_set_lab_url = "#{lab_url_prefix}/subject-sets/#{ss_import.subject_set_id}"
    @subject_set_name = ss_import.subject_set.display_name

    @no_errors = ss_import.failed_count.zero?
    import_status = @no_errors ? 'was successful!' : 'completed with errors'
    subject = "Your iNaturalist subject import #{import_status}"

    mail(to: @email_to, subject: subject)
  end
end

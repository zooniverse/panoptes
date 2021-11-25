class DumpMailer
  attr_reader :resource, :medium, :dump_target

  def initialize(resource, medium, dump_target)
    @resource = resource
    @medium = medium
    @dump_target = dump_target
  end

  def send_email
    return unless emails.present?

    mailer.perform_async(
      resource.id,
      resource.model_name.singular,
      lab_export_url,
      emails
    )
  end

  def mailer
    "#{dump_target.singularize}_data_mailer_worker".camelize.constantize
  end

  def emails
    metadata = medium.metadata || {}
    recipients = metadata['recipients']
    # fallback to project communication emails if receipients are not set or empty
    return resource.communication_emails if recipients.blank?

    # find the specified recipient emails
    User.where(id: recipients).pluck(:email)
  end

  def lab_export_url
    # lab urls should be identified by the project
    project_id = resource.id
    # use the SubjectSet | Workflow project id in the URL
    project_id = resource.project_id if resource.respond_to?(:project_id)

    suffix = ''
    # add the unique ID for Subject Set specific suffix exports page behaviours
    suffix = "?subject-sets=#{resource.id}" if resource.is_a?(SubjectSet)

    "#{Panoptes.frontend_url}/lab/#{project_id}/data-exports#{suffix}"
  end
end

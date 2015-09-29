module DumpMailerWorker
  extend ActiveSupport::Concern

  def mailer
    "#{dump_target.singularize}_data_mailer_worker".camelize.constantize
  end

  def emails
    if recipients = medium.try(:metadata).try(:[], "recipients")
      User.where(id: recipients).pluck(:email)
    else
      [project.owner.email]
    end
  end

  def send_email
    mailer.perform_async(@project.id, media_get_url, emails)
  end

  def media_get_url(expires=24*60)
    medium.get_url(get_expires: expires)
  end
end

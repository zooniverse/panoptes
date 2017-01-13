require 'csv'

class EmailsProjectsExportWorker
  include Sidekiq::Worker
  include DumpCommons
  include DumpEmails

  sidekiq_options queue: :data_low

  attr_reader :project

  def perform(project_id)
    @project = Project.find(project_id)
    begin
      emails_to_csv_file
      upload_dump
    ensure
      cleanup_dump
    end
  rescue ActiveRecord::RecordNotFound
  end

  private

  def user_emails
    User
      .joins(:project_preferences)
      .where(user_project_preferences: { project_id: project.id, email_communication: true })
      .active
      .where(valid_email: true)
      .select(:id, :email)
  end

  def export_type
    project.slug
  end
end

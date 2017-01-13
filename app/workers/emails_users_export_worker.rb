require 'csv'

class EmailsUsersExportWorker
  include Sidekiq::Worker
  include DumpCommons
  include DumpEmails

  sidekiq_options queue: :data_low

  attr_reader :export_type

  def perform(export_type=:global)
    @export_type = export_type
    begin
      emails_to_csv_file
      upload_dump
    ensure
      cleanup_dump
    end
  end

  private

  def user_emails
    export_field = case export_type
    when :global
      :global_email_communication
    when :beta
      :beta_email_communication
    end
    emailable_users(export_field).select(:id, :email, export_field)
  end

  def emailable_users(export_field)
    @emailable_users ||= User
      .active
      .where(valid_email: true)
      .where(export_field => true)
  end
end

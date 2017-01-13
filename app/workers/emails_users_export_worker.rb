require 'csv'

class EmailsUsersExportWorker
  include Sidekiq::Worker
  include DumpCommons

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

  def emails_to_csv_file
    CSV.open(csv_file_path, 'wb') do |csv|
      user_emails.find_in_batches do |user_batch|
        user_batch.each { |user| csv << [ user.email ] }
      end
    end
  end

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

  def write_to_s3
    storage_path = MediaStorage.stored_path("application/x-gzip", "email_exports")
    prefix = File.dirname(storage_path)
    file_paths = File.basename(storage_path).split(".")
    file_paths.shift
    exts = file_paths.join(".")
    file_name = "#{export_type}_email_list"
    s3_path = "#{prefix}/#{file_name}.#{exts}"
    MediaStorage.put_file(s3_path, gzip_file_path, storage_opts(file_name))
  end

  def storage_opts(file_name)
    {
      private: true,
      compressed: true,
      content_disposition: "attachment; filename=\"#{file_name}.csv\""
    }
  end
end

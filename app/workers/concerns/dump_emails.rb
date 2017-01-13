module DumpEmails
  def emails_to_csv_file
    CSV.open(csv_file_path, 'wb') do |csv|
      user_emails.find_in_batches do |user_batch|
        user_batch.each { |user| csv << [ user.email ] }
      end
    end
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

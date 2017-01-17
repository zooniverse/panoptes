module DumpEmails
  def emails_to_csv_file
    CSV.open(csv_file_path, 'wb') do |csv|
      user_emails.find_in_batches do |user_batch|
        user_batch.each { |user| csv << [ user.email ] }
      end
    end
  end

  def write_to_s3
    storage_path = storage_adapter.stored_path("application/x-gzip", "email_exports")
    prefix = File.dirname(storage_path)
    file_paths = File.basename(storage_path).split(".")
    file_paths.shift
    exts = file_paths.join(".")
    file_name = "#{export_type}_email_list"
    s3_path = "#{prefix}/#{file_name}.#{exts}"
    storage_adapter.put_file(s3_path, gzip_file_path, storage_opts(file_name))
  end

  def storage_opts(file_name)
    {
      private: true,
      compressed: true,
      content_disposition: "attachment; filename=\"#{file_name}.csv\""
    }
  end

  private

  # TODO: use zoo wide email export media resources once bucket paths
  # can be set per medium, https://github.com/zooniverse/Panoptes/issues/2140
  def storage_adapter
    return @storage_adapter if @storage_adapter
    storage_config = Panoptes::StorageAdapter.configuration
    adapter = storage_config[:adapter]
    storage_opts = { bucket: ENV["EMAIL_EXPORT_S3_BUCKET"] }
    storage_opts = storage_opts.merge(storage_config.except(:adapter))
    @storage_adapter = MediaStorage.send(:load_from_included, adapter).new(storage_opts)
  end
end

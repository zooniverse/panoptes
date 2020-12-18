# frozen_string_literal: true

module CsvDumps
  # Custom 'Medium' duck type class to interface directly to
  # a custom location (bucket, paths) on s3 to securely host export files
  class DirectToS3
    attr_reader :export_type

    class UnencryptedBucket < StandardError; end

    def initialize(export_type)
      @export_type = export_type
    end

    def metadata
      {}
    end

    def save!
      true
    end

    def put_file(gzip_file_path, compressed: true)
      check_encrypted_bucket
      s3_path = emails_export_path
      storage_adapter.put_file(
        s3_path,
        gzip_file_path,
        put_file_opts
      )
    end

    def storage_adapter(adapter='aws')
      return @storage_adapter if @storage_adapter

      storage_opts = {
        bucket: ENV.fetch("EMAIL_EXPORT_S3_BUCKET", 'zooniverse-exports'),
        prefix: ENV.fetch("EMAIL_EXPORT_S3_PREFIX", "#{Rails.env}/")
      }
      @storage_adapter = MediaStorage.send(:load_adapter, adapter, storage_opts)
    end

    private

    def put_file_opts
      {
        private: true,
        compressed: true,
        content_disposition: "attachment; filename=\"#{export_file_name}.csv\""
      }
    end

    def emails_export_path(path="email_exports")
      storage_path = storage_adapter.stored_path("text/csv", path)
      prefix = File.dirname(storage_path)
      file_paths = File.basename(storage_path).split(".")
      file_paths.shift
      exts = file_paths.join(".")
      "#{prefix}/#{export_file_name}.#{exts}"
    end

    def export_file_name
      "#{export_type}_email_list"
    end

    def check_encrypted_bucket
      unless storage_adapter.safe_for_private_upload?
        raise UnencryptedBucket.new("the destination bucket is not encrypted")
      end
    end
  end
end

module CsvDumps
  # TODO: use zoo wide email export media resources once bucket paths
  # can be set per medium, https://github.com/zooniverse/Panoptes/issues/2140
  # At that point normal Medium objects should be used instead of this.
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

      storage_path = storage_adapter.stored_path("application/x-gzip", "email_exports")
      prefix = File.dirname(storage_path)
      file_paths = File.basename(storage_path).split(".")
      file_paths.shift
      exts = file_paths.join(".")
      file_name = "#{export_type}_email_list"
      s3_path = "#{prefix}/#{file_name}.#{exts}"
      storage_adapter.put_file(s3_path, gzip_file_path, storage_opts(file_name))
    end

    private

    def storage_opts(file_name)
      {
        private: true,
        compressed: true,
        content_disposition: "attachment; filename=\"#{file_name}.csv\"",
        signature_version: :v4
      }
    end

    def storage_adapter
      return @storage_adapter if @storage_adapter
      storage_config = Panoptes::StorageAdapter.configuration
      adapter = storage_config[:adapter]
      storage_opts = {
        bucket: ENV.fetch("EMAIL_EXPORT_S3_BUCKET", 'zooniverse-exports'),
        prefix: ENV.fetch("EMAIL_EXPORT_S3_PREFIX", "emails/#{Rails.env}/")
      }
      @storage_adapter = MediaStorage.send(:load_adapter, adapter, storage_opts)
    end

    def check_encrypted_bucket
      binding.pry
      unless storage_adapter.encrypted_bucket?
        raise UnencryptedBucket.new("the destination bucket is not encrypted")
      end
    end
  end
end

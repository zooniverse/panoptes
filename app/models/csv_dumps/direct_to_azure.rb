# frozen_string_literal: true

module CsvDumps
  # Custom 'Medium' duck type class to interface directly to
  # a custom location (storage account, container, paths) on Azure
  # to ensure the export files are securely hosted
  class DirectToAzure
    attr_reader :export_type

    class NonPrivateContainer < StandardError; end

    def initialize(export_type)
      @export_type = export_type
    end

    def metadata
      {}
    end

    def save!
      true
    end

    def put_file(gzip_file_path, _compressed: true)
      check_private_container
      azure_container_path = emails_export_path
      storage_adapter.put_file(
        azure_container_path,
        gzip_file_path,
        put_file_opts
      )
    end

    def storage_adapter(adapter='azure')
      return @storage_adapter if @storage_adapter

      storage_opts = {}
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

    def check_private_container
      return if storage_adapter.safe_for_private_upload?

      raise NonPrivateContainer, 'the destination container is public'
    end
  end
end

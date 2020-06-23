module MediaStorage
  class AzureAdapter < AbstractAdapter
    def initialize(opts={})
      @storage_account_name = opts[:storage_account_name]
      @container_name = opts[:storage_container]
      @prefix = opts[:prefix] || Rails.env

      @client = Azure::Storage::Blob::BlobService.create(
        storage_account_name: opts[:storage_account_name],
        storage_access_key: opts[:storage_access_key]
      )
      @sas_generator = Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(
        opts[:storage_account_name],
        opts[:storage_access_key]
      )
    end

    def stored_path(content_type, media_type, *path_prefix)
      # to do
    end

    def get_path(path, opts={})
      full_path = @container_name + '/' + @prefix + '/' + path
      sas_token = @sas_generator.generate_service_sas_token full_path, service: "b", resource: "b", permissions: "racwd"
      sas_uri = "https://#{@storage_account_name}.blob.core.windows.net/#{full_path}?#{sas_token}"
    end

    def put_path(path, opts={})
      # to do
    end

    def put_file(path, file_path, opts={})
      file = open file_path
      content = file.read
      file.close
      @client.create_block_blob(@container_name, path, content)
    end

    def delete_file(path)
      # to do
    end

    def encrypted_bucket?
      # to do
    end
  end
end
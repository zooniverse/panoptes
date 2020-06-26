module MediaStorage
  class AzureAdapter < AbstractAdapter
    DEFAULT_EXPIRES_IN = 3 # time in minutes

    def initialize(opts={})
      @storage_account_name = opts[:storage_account_name]
      @container_name = opts[:storage_container]
      @prefix = opts[:prefix] || Rails.env
      @get_expiration = opts.dig(:expiration, :get) || DEFAULT_EXPIRES_IN
      @put_expiration = opts.dig(:expiration, :put) || DEFAULT_EXPIRES_IN

      @client = Azure::Storage::Blob::BlobService.create(
        storage_account_name: opts[:storage_account_name],
        storage_access_key: opts[:storage_access_key]
      )
      @sas_generator = Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(
        opts[:storage_account_name],
        opts[:storage_access_key]
      )
    end

    def stored_path(content_type, medium_type, *path_prefix)
      # do we want to change anything about how the stored_path is generated? this is copied from aws
      extension = get_extension(content_type)
      path = @prefix.to_s
      path += "/" unless path[-1] == '/'
      path += "#{medium_type}/"
      path += "#{path_prefix.join('/')}/" unless path_prefix.empty?
      path + "#{SecureRandom.uuid}.#{extension}"
    end

    def get_path(path, opts={})
      # to do: add in expiration and other opts
      # to do: narrow down which permissions we want to provide
      expires_in = opts[:get_expires] || @get_expiration # time in minutes
      expiry_time = get_expiry_time(expires_in)
      sas_token = @sas_generator.generate_service_sas_token(
        path,
        service: 'b',
        resource: 'b',
        permissions: 'racwd',
        expiry: expiry_time
      )
      generate_sas_url(path, sas_token)
    end

    def put_path(path, opts={})
      content_type = opts[:content_type]
      expires_in = opts[:put_expires] || @put_expiration # time in minutes
      expiry_time = get_expiry_time(expires_in)
      sas_token = @sas_generator.generate_service_sas_token(
        path,
        service: 'b',
        resource: 'b',
        permissions: 'racwd',
        expiry: expiry_time,
        content_type: content_type
      )
      generate_sas_url(path, sas_token)
    end

    def put_file(path, file_path, opts={})
      # to do: implement options
      content = get_file_contents file_path
      @client.create_block_blob(@container_name, path, content)
    end

    def delete_file(path)
      @client.delete_blob(@container_name, path)
    end

    def encrypted_bucket?
      # to do
    end

    private

    def get_file_contents(file_path)
      file = File.open file_path
      content = file.read
      file.close
      content
    end

    # @param expires_in [int]: time increment in minutes
    def get_expiry_time(expires_in)
      (Time.now + expires_in.minutes).iso8601 # required format is ISO 8601
    end

    def generate_sas_url(path, sas_token)
      "https://#{@storage_account_name}.blob.core.windows.net/#{path}?#{sas_token}"
    end
  end
end

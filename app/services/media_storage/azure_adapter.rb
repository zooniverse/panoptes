module MediaStorage
  class AzureAdapter < AbstractAdapter
    DEFAULT_EXPIRES_IN = 3 # time in minutes

    def initialize(opts={})
      @storage_account_name = opts[:storage_account_name]
      @container = opts[:storage_container] || Rails.env
      @get_expiration = opts.dig(:expiration, :get) || DEFAULT_EXPIRES_IN
      @put_expiration = opts.dig(:expiration, :put) || DEFAULT_EXPIRES_IN

      @client = Azure::Storage::Blob::BlobService.create(
        storage_account_name: opts[:storage_account_name],
        storage_access_key: opts[:storage_access_key]
      )
      @signer = Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(
        opts[:storage_account_name],
        opts[:storage_access_key]
      )
    end

    def stored_path(content_type, medium_type, *path_prefix)
      extension = get_extension(content_type)
      path = "#{medium_type}/"
      path += "#{path_prefix.join('/')}/" unless path_prefix.empty?
      path + "#{SecureRandom.uuid}.#{extension}"
    end

    def get_path(path, opts={})
      expires_in = opts[:get_expires] || @get_expiration # time in minutes
      expiry_time = get_expiry_time(expires_in)

      @signer.signed_uri(
        generate_uri(path), false,
        service: 'b', # blob
        permissions: 'rcw', # read create write
        expiry: expiry_time,
      )
    end

    def put_path(path, opts={})
      content_type = opts[:content_type]
      expires_in = opts[:put_expires] || @put_expiration # time in minutes
      expiry_time = get_expiry_time(expires_in)

      @signer.signed_uri(
        generate_uri(path), false,
        service: 'b', # blob
        permissions: 'rcw', # read create write
        expiry: expiry_time,
        content_type: content_type
      )
    end

    def put_file(path, file_path, opts={})
      # to do: implement options
      content = get_file_contents file_path
      @client.create_block_blob(@container, path, content)
    end

    def delete_file(path)
      @client.delete_blob(@container, path)
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
      Time.now.utc.advance(minutes: expires_in).iso8601 # required format is UTC time zone, ISO 8601
    end

    def generate_uri(path)
      URI("https://#{@storage_account_name}.blob.core.windows.net/#{@container}/#{path}")
    end
  end
end
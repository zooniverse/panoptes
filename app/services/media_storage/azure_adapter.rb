module MediaStorage
  class AzureAdapter < AbstractAdapter
    DEFAULT_EXPIRES_IN = 3 # time in minutes

    def initialize(opts={})
      @storage_account_name = opts[:storage_account_name]
      @container = opts[:storage_container] || Rails.env
      @get_expiration = opts.dig(:expiration, :get) || DEFAULT_EXPIRES_IN
      @put_expiration = opts.dig(:expiration, :put) || DEFAULT_EXPIRES_IN

      @client = initialize_blob_client
      @signer = initialize_signer
    end

    def stored_path(content_type, medium_type, *path_prefix)
      extension = get_extension(content_type)
      path = "#{medium_type}/"
      path += "#{path_prefix.join('/')}/" unless path_prefix.empty?
      path + "#{SecureRandom.uuid}.#{extension}"
    end

    def get_path(path, opts={})
      # TO DO: implement private v public uploads
      expires_in = opts[:get_expires] || @get_expiration # time in minutes
      expiry_time = get_expiry_time(expires_in)

      @signer.signed_uri(
        generate_uri(path), false,
        service: 'b', # blob
        permissions: 'rcw', # read create write
        expiry: expiry_time
      ).to_s
    end

    def put_path(path, opts={})
      # TO DO: implement private v public uploads
      content_type = opts[:content_type]
      expires_in = opts[:put_expires] || @put_expiration # time in minutes
      expiry_time = get_expiry_time(expires_in)

      @signer.signed_uri(
        generate_uri(path), false,
        service: 'b', # blob
        permissions: 'rcw', # read create write
        expiry: expiry_time,
        content_type: content_type
      ).to_s
    end

    def put_file(path, file_path, opts={})
      # TO DO: implement private v public uploads
      upload_options = { content_type: opts[:content_type] }
      upload_options[:content_encoding] = 'gzip' if opts[:compressed]
      if opts[:content_disposition]
        upload_options[:content_disposition] = opts[:content_disposition]
      end

      content = get_file_contents file_path
      @client.create_block_blob(@container, path, content, upload_options)
    end

    def delete_file(path)
      # TO DO: implement private v public uploads
      @client.delete_blob(@container, path)
    end

    def encrypted_bucket?
      # encryption is automatically enabled for all azure storage accounts and
      # cannot be disabled, so this is always true
      true
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

    def initialize_blob_client(opts)
      Azure::Storage::Blob::BlobService.create(
        storage_account_name: opts[:storage_account_name],
        storage_access_key: opts[:storage_access_key]
      )
    end

    def initialize_signer(opts)
      Azure::Storage::Common::Core::Auth::SharedAccessSignature.new(
        opts[:storage_account_name],
        opts[:storage_access_key]
      )
    end
  end
end

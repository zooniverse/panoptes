module MediaStorage
  class AwsAdapter < AbstractAdapter
    attr_accessor :prefix, :bucket
    attr_reader :s3

    S3_CLIENT_OPTS = %i(
      access_key_id
      secret_access_key
      region
    ).freeze

    def initialize(opts={})
      @prefix = opts[:prefix] || Rails.env
      @bucket = opts[:bucket]
      @get_expiration = opts.dig(:expiration, :get) || 60
      @put_expiration = opts.dig(:expiration, :put) || 20
      @s3 = Aws::S3::Resource.new(client: s3_client(opts.slice(*S3_CLIENT_OPTS)))
    end

    def bucket
      return @bucket unless @bucket.is_a?(String)
      @bucket = s3.bucket(@bucket)
    end

    def stored_path(content_type, medium_type, *path_prefix)
      extension = get_extension(content_type)
      path = "#{prefix}"
      path += "/" unless path[-1] == '/'
      path += "#{medium_type}/"
      path += "#{path_prefix.join('/')}/" unless path_prefix.empty?
      path += "#{SecureRandom.uuid}.#{extension}"
      path
    end

    def get_path(path, opts={})
      expires = expires_in(opts[:get_expires] || @get_expiration)
      if opts[:private]
        object(path).presigned_url(:get, expires_in: expires).to_s
      else
        "https://#{path}"
      end
    end

    def put_path(path, opts={})
      content_type = opts[:content_type]
      expires = expires_in(opts[:put_expires] || @put_expiration)
      object(path).presigned_url(
        :put,
        content_type: content_type,
        expires_in: expires,
        acl: opts[:private] ? 'private' : 'public-read'
      ).to_s
    end

    def put_file(path, file_path, opts={})
      upload_options = {
        content_type: opts[:content_type],
        acl: opts[:private] ? 'private' : 'public-read'
      }
      upload_options[:content_encoding] = 'gzip' if opts[:compressed]
      if opts[:content_disposition]
        upload_options[:content_disposition] = opts[:content_disposition]
      end
      object(path).upload_file(file_path, upload_options)
    end

    def delete_file(path)
      object(path).delete
    end

    private

    def object(path)
      check_path(path)
      bucket.object(path)
    end

    def expires_in(mins)
      (mins * 60).to_i
    end

    def s3_client(client_opts)
      client_opts[:region] ||= ENV.fetch('AWS_REGION', 'us-east-1')
      Aws::S3::Client.new(client_opts)
    end
  end
end

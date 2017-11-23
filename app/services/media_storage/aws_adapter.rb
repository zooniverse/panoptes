module MediaStorage
  class AwsAdapter < AbstractAdapter
    attr_accessor :prefix, :bucket

    def initialize(opts={})
      @prefix = opts[:prefix] || Rails.env
      @bucket = opts[:bucket]
      @get_expiration = opts.dig(:expiration, :get) || 60
      @put_expiration = opts.dig(:expiration, :put) || 20
      keys = opts.slice(:access_key_id, :secret_access_key)
      AWS.config(keys) unless keys.empty?
    end

    def bucket
      return @bucket unless @bucket.is_a?(String)
      @bucket = s3.buckets[@bucket]
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
        object(path).url_for(:read,
                             secure: true,
                             expires: expires).to_s
      else
        "https://#{path}"
      end
    end

    def put_path(path, opts={})
      content_type = opts[:content_type]
      expires = expires_in(opts[:put_expires] || @put_expiration)
      object(path).url_for(:write,
                           secure: true,
                           content_type: content_type,
                           expires: expires,
                           response_content_type: content_type,
                           acl: opts[:private] ? 'private' : 'public-read').to_s
    end

    def put_file(path, file_path, opts={})
      upload_options = {
                        file: file_path,
                        content_type: opts[:content_type],
                        acl: opts[:private] ? 'private' : 'public-read'
                       }
      upload_options[:content_encoding] = 'gzip' if opts[:compressed]
      if opts[:content_disposition]
        upload_options[:content_disposition] = opts[:content_disposition]
      end
      if opts[:signature_version]
        upload_options[:signature_version] = opts[:signature_version]
      end
      object(path).write(**upload_options)
    end

    def delete_file(path)
      object(path).delete
    end

    private

    def object(path)
      check_path(path)
      bucket.objects[path]
    end

    def s3
      @s3 ||= AWS::S3.new
    end

    def expires_in(mins)
      (mins * 60).to_i
    end
  end
end

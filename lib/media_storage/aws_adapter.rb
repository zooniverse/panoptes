module MediaStorage
  class AwsAdapter < AbstractAdapter

    DEFAULT_PUT_EXPIRATION = 20
    DEFAULT_GET_EXPIRATION = 60

    attr_accessor :prefix, :bucket

    def initialize(opts={})
      @prefix = opts[:prefix] || Rails.env
      @bucket = opts[:bucket]
      @get_expiration = opts.fetch(:expiration, {})[:get] || DEFAULT_PUT_EXPIRATION
      @put_expiration = opts.fetch(:expiration, {})[:put] || DEFAULT_GET_EXPIRATION
      keys = opts.slice(:access_key_id, :secret_access_key)
      aws.config(keys) unless keys.empty?
    end

    def aws
      AWS
    end

    def bucket
      return @bucket unless @bucket.is_a?(String)
      @bucket = s3.buckets[@bucket]
    end

    def stored_path(content_type, medium_type, *path_prefix)
      extension = MIME::Types[content_type].first.extensions.first
      path = "#{prefix}"
      path += "/" unless path[-1] == '/'
      path += "#{medium_type}/"
      path += "#{path_prefix.join('/')}/" unless path_prefix.empty?
      path += "#{SecureRandom.uuid}.#{extension}"
      path
    end

    def get_path(path, opts={})
      expires = (@get_expiration || opts[:expires]).minutes.from_now
      if opts[:private]
        object(path).url_for(:read,
                             secure: true,
                             expires_in: expires).to_s
      else
        "https://#{path}"
      end
    end

    def put_path(path, opts={})
      content_type = opts[:content_type]
      expires = (@put_expiration || opts[:expires]).minutes.from_now
      object(path).url_for(:write,
                           secure: true,
                           content_type: content_type,
                           expires_in: expires,
                           response_content_type: content_type,
                           acl: opts[:private] ? 'private' : 'public-read').to_s
    end

    def put_file(path, file_path, opts={})
      object(path).write(file: file_path,
                         content_type: opts[:content_type],
                         acl: opts[:private] ? 'private' : 'public-read')
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
  end
end

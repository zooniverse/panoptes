module MediaStorage
  class AwsAdapter < AbstractAdapter
    attr_accessor :prefix, :bucket

    def initialize(opts={})
      @prefix = opts[:prefix] || Rails.env
      @bucket = opts[:bucket]
      keys = opts.slice(:access_key_id, :secret_access_key)
      aws.config(keys) unless keys.empty?
    end

    def aws
      AWS
    end

    def bucket
      @bucket unless bucket.is_a?(String)
      @bucket = s3.buckets[@bucket]
    end

    def stored_path(content_type, medium_type, *path_prefix)
      extension = MIME::Types[mime].first.extensions.first
      path = "#{prefix}/#{medium_type}/"
      path += "#{path_prefix.join('/')}/" unless path_prefix.empty?
      path += "#{SecureRandom.uuid}.#{extension}"
      path
    end

    def get_path(path, opts={})
      "https://#{path}"
    end

    def put_path(path, mime_type: nil)
      obj = bucket.objects[path]
      obj.url_for(:write, {secure: true,
                           content_type: mime_type,
                           expires_in: 20.minutes.from_now,
                           response_content_type: mime_type,
                           acl: 'public-read'}).to_s
    end

    private

    def s3
      @s3 ||= AWS::S3.new
    end
  end
end

module MediaStorage
  class AbstractAdapter
    def initialize(opts={})
      @opts = opts
    end

    def put_file(path, file_path, opts={})
      raise NotImplementedError
    end

    def stored_path(content_type, media_type, *path_prefix)
      raise NotImplementedError
    end

    # Returns URL/path to be used to make a GET request to the storage service
    def get_path(path, opts={})
      raise NotImplementedError
    end

    # Returns URL/path to be used to make a PUT request to the storage service
    def put_path(path, opts={})
      raise NotImplementedError
    end

    # Returns required headers for making a put request to the storage service
    def headers_for_direct_upload
      raise NotImplementedError
    end

    def delete_file(path, opts={})
      raise NotImplementedError
    end

    def encrypted_bucket?
      raise NotImplementedError
    end

    def configure
      yield self if block_given?
    end

    private

    def check_path(path)
      if path.blank?
        raise EmptyPathError.new("A storage path must be specified.")
      end
    end

    def get_extension(content_type)
      case content_type
      when "application/x-gzip"
        "tar.gz"
      else
        get_mime_type(content_type).extensions.first
      end
    end

    def get_mime_type(content_type)
      known_types = MIME::Types[content_type]
      raise UnknownContentType if known_types.blank?
      known_types.first
    end
  end
end

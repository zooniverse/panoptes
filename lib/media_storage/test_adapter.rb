module MediaStorage
  class TestAdapter < AbstractAdapter
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
      "https://#{path}"
    end
  end
end

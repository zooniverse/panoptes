module MediaStorage
  class DiskAdapter < AbstractAdapter
    def stored_path(content_type, medium_type, *path_prefix)
      extension = get_extension(content_type)
      path = "#{medium_type}/"
      path += "#{path_prefix.join('/')}/" unless path_prefix.empty?
      path += "#{SecureRandom.uuid}.#{extension}"
      path
    end

    def put_file(path, file_path, opts={})
      destination = Rails.root.join("tmp", "media_storage", path)
      FileUtils.mkdir_p(File.dirname(destination))
      FileUtils.cp(file_path, destination)
    end

    def get_path(path, opts={})
      "https://#{path}"
    end

    def put_path(path, opts={})
      "https://#{path}"
    end
  end
end

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

    def get_path(path, opts={})
      raise NotImplementedError
    end

    def put_path(path, opts={})
      raise NotImplementedError
    end

    def configure
      yield self if block_given?
    end
  end
end

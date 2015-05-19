module MediaStorage
  class AbstractAdapter

    class EmptyPathError < StandardError; end

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

    def delete_file(path)
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
  end
end

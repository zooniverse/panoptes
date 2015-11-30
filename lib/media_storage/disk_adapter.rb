module MediaStorage
  class DiskAdapter < AbstractAdapter

    class EmptyPathError < StandardError; end

    attr_reader :root

    def initialize(opts={})
      @root = Pathname.new(opts.fetch(:path)).expand_path
    end

    def put_file(path, file_path, opts={})
      FileUtils.mkdir_p(File.dirname(root.join(path)))
      FileUtils.cp(file_path, root.join(path))
    end

    def stored_path(content_type, media_type, *path_prefix)
      raise NotImplementedError
    end

    def get_path(path, opts={})
      root.join(path)
    end

    def put_path(path, opts={})
      root.join(path)
    end

    def delete_file(path)
      FileUtils.rm(root.join(path))
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

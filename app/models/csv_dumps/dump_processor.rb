module CsvDumps
  class DumpProcessor
    include ActiveSupport::Callbacks

    attr_reader :csv_dump, :formatter, :scope, :medium

    define_callbacks :dump
    define_callbacks :upload
    define_callbacks :cleanup

    def initialize(formatter, scope, medium, csv_dump = CsvDump.new)
      @formatter = formatter
      @scope = scope
      @medium = medium
      @csv_dump = csv_dump
    end

    def execute(&block)
      perform_dump(&block)
      upload_dump
    ensure
      cleanup_dump
    end

    def perform_dump
      csv_dump << formatter.headers if formatter.headers

      scope.each do |model|

        # TODO: search for an existing formatted row
        # by classification fk presence
        # use this instead of formatting again

        formatter.to_rows(model).each do |row|
          csv_dump << row
        end
        # TODO: the interface to set the formatter's model
        # needs to be generalized instead of using the
        # to_rows method to set the model instance
        # and then reflect on it for formatter
        #
        # In the meantime we can rely on the order of execution
        # to set the formatter to have the new model
        # and pass this to our calling context block

        # TODO: skip yielding the block if
        # we're reusing a previously formatted model
        yield formatter if block_given?
      end
    end

    def upload_dump
      if block_given?
        # yield row
        binding.pry
      end
      gzip_file_path = csv_dump.gzip!
      write_to_s3(gzip_file_path)
      set_ready_state
    end

    def cleanup_dump
      csv_dump.cleanup!
    end

    private

    def set_ready_state
      medium.metadata["state"] = 'ready'
      medium.save!
    end

    def write_to_s3(gzip_file_path)
      medium.put_file(gzip_file_path, compressed: true)
    end
  end
end

module CsvDumps
  class CachingDumpProcessor < DumpProcessor
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

        # TODO: when re-using pre-formatted records
        # make sure we inject the dump specific data (user_ip)
        # by using the formatter or cache directly
        # cache.secure_user_ip(classification.user_ip.to_s)

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
  end
end

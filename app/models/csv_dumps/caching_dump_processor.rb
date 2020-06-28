# frozen_string_literal: true

module CsvDumps
  class CachingDumpProcessor < DumpProcessor
    attr_accessor :yield_block

    def initialize(formatter, scope, medium, csv_dump=nil, &block)
      super(formatter, scope, medium, csv_dump)
      @yield_block = block
    end

    def perform_dump
      csv_dump << formatter.headers if formatter.headers

      scope.each do |model|
        # can we use the caching export?
        if (cached_export = model.cached_export)

          # wrap the formatter with a caching formatter
          # that uses the cached export for most
          # of the work
          # and falls back to the normall formatter
          # for any non-cached attributes (user_id, etc)
          # cache_formatter = CachingFormatter
          formatter.to_rows(model).each do |row|
            csv_dump << row
          end
        else
          formatter.to_rows(model).each do |row|
            csv_dump << row
          end
        end
        # TODO: the interface to set the formatter's model
        # needs to be generalized instead of using the
        # to_rows method to set the model instance
        # and then reflect on it for formatter

        # In the meantime we can rely on the order of execution
        # to set the formatter to have the new model
        # and pass this to our calling context block


        # yield to the external context that knows how to
        # persistence the cacheable resource
        yield_block.call(formatter)
      end
    end

    class CachingFormatter
      attr_reader :cached_resource, :formatter

      def initialize(cached_resource, formatter)
        @cached_resource = cached_resource
        @formatter = formatter
      end
    end
  end
end

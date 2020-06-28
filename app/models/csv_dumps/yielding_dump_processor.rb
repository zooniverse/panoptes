# frozen_string_literal: true

module CsvDumps
  class YieldingDumpProcessor < DumpProcessor
    attr_accessor :yield_block

    def initialize(formatter, scope, medium, csv_dump, &block)
      super(formatter, scope, medium, csv_dump)
      @yield_block = block
    end

    def perform_dump
      csv_dump << formatter.headers if formatter.headers

      scope.each do |model|
        formatter.to_rows(model).each do |row|
          csv_dump << row
        end

        yield_block.call(formatter)
      end
    end
  end
end

module CsvDumps
  class DumpScope
    attr_reader :resource

    def initialize(resource)
      @resource = resource
    end

    private

    def read_from_database(&block)
      DatabaseReplica.read("dump_data_from_read_replica", &block)
    end
  end
end

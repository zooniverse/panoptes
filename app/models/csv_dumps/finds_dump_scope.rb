module CsvDumps
  class FindsDumpScope
    def self.find(resource_type, resource_id)
      resource_type.camelize.constantize.find(resource_id)
    end
  end
end

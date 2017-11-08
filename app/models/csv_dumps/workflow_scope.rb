module CsvDumps
  class WorkflowScope < DumpScope
    def each
      read_from_database do
        resource.workflows.find_each do |workflow|
          yield workflow

          while workflow = workflow.previous_version
            yield workflow
          end
        end
      end
    end
  end
end

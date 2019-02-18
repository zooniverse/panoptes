module CsvDumps
  class WorkflowScope < DumpScope
    def each
      read_from_database do
        resource.workflows.find_each do |workflow|
          workflow.workflow_versions.find_each do |workflow_version|
            yield workflow_version
          end
        end
      end
    end
  end
end

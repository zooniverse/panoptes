module CsvDumps
  class WorkflowContentScope < DumpScope
    def each
      read_from_database do
        resource.workflows.each do |workflow|
          workflow.workflow_contents.find_each do |wc|
            yield wc

            while wc = wc.previous_version
              yield wc
            end
          end
        end
      end
    end
  end
end

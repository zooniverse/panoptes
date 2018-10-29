# lib/backfill_workflow_versions.rb

module Tasks
  class BackfillWorkflowVersions
    def backfill(workflow)
      workflow.versions.each do |version|
        workflow_at_version = version.reify
      end
    end
    # Code here
  end
end

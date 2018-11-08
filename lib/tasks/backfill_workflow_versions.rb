# lib/backfill_workflow_versions.rb

module Tasks
  class BackfillWorkflowVersions
    def backfill(workflow)
      workflow_content = workflow.primary_content

      workflow.versions.each_with_index do |w_version, w_index|
        workflow_at_version = w_version.reify

        # reify returns nil for create. I think it's not correct to then just
        # set it to the actual workflow, since that is always the latest version
        # but it is what the dump cache is doing.
        workflow_at_version ||= workflow

        # It is hard to figure out which combinations of major/minor actually
        # existed. For now I'm opting to simply generate all permutations.
        # I'd love to have a discussion on how to do this more wisely.
        workflow_content.versions.each_with_index do |wc_version, wc_index|
          workflow_content_at_version = wc_version.reify

          # reify returns nil for create. I think it's not correct to then just
          # set it to the actual workflow, since that is always the latest version
          # but it is what the dump cache is doing.
          workflow_content_at_version ||= workflow_content

          workflow.workflow_versions.create! \
            tasks: workflow_at_version.tasks,
            first_task: workflow_at_version.first_task,
            strings: workflow_content_at_version.strings,
            major_number: w_index,
            minor_number: wc_index
        end
      end
    end
  end
end

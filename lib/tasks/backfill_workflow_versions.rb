# lib/backfill_workflow_versions.rb

module Tasks
  class BackfillWorkflowVersions
    def backfill(workflow)
      workflow_content = workflow.primary_content

      # It is hard to figure out which combinations of major/minor actually
      # existed. For now I'm opting to simply generate all permutations.
      # I'd love to have a discussion on how to do this more wisely.
      #
      workflow_versions = workflow.versions[1..-1].map(&:reify) + [workflow]
      workflow_versions.each_with_index do |workflow_at_version, w_index|

        workflow_content_versions = workflow_content.versions[1..-1].map(&:reify) + [workflow_content]
        workflow_content_versions.each_with_index do |workflow_content_at_version, wc_index|

          workflow.workflow_versions.create! \
            tasks: workflow_at_version.tasks,
            first_task: workflow_at_version.first_task,
            strings: workflow_content_at_version.strings,
            major_number: w_index + 1,
            minor_number: wc_index + 1

        end
      end
    end
  end
end

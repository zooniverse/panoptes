# lib/backfill_workflow_versions.rb

module Tasks
  class BackfillWorkflowVersions
    def backfill_version(workflow, w_index, wc_index, workflow_at_version, workflow_content_at_version)
      workflow_version = WorkflowVersion.find_or_initialize_by(workflow_id: workflow.id,
                                                                major_number: w_index + 1,
                                                                minor_number: wc_index + 1)
      workflow_version.tasks = workflow_at_version.tasks
      workflow_version.first_task = workflow_at_version.first_task
      workflow_version.strings = workflow_content_at_version.strings
      workflow_version.save!
      print '.'
    end

    def backfill(workflow)
      workflow_content = workflow.primary_content

      # It is hard to figure out which combinations of major/minor actually
      # existed. For now I'm opting to simply generate all permutations.
      # I'd love to have a discussion on how to do this more wisely.
      #
      puts "Loading workflow versions"
      workflow_versions = workflow.versions[1..-1].map(&:reify) + [workflow]
      puts "Loading workflow content versions"
      workflow_content_versions = workflow_content.versions[1..-1].map(&:reify) + [workflow_content]

      puts "Loaded #{workflow_versions.size} workflow versions, #{workflow_content_versions.size} workflow content versions"

      puts "Finding which versions are in use"
      used_versions = Standby.on_standby do
        Classification.where(workflow_id: workflow.id).select(:workflow_version).distinct.map(&:workflow_version)
      end

      puts "Backfilling #{used_versions.size} versions"
      used_versions.each do |used_version|
        puts used_version
        workflow_index, workflow_content_index = used_version.split(".").map(&:to_i)

        workflow_at_version = workflow_versions[workflow_index - 1]
        workflow_content_at_version = workflow_content_versions[workflow_content_index - 1]

        backfill_version(workflow, workflow_index - 1, workflow_content_index - 1, workflow_at_version, workflow_content_at_version)
      end

      # workflow_versions.each_with_index do |workflow_at_version, w_index|
      #   workflow_content_versions.each_with_index do |workflow_content_at_version, wc_index|
      #     backfill_version(workflow, w_index, wc_index, workflow_at_version, workflow_content_at_version)
      #   end
      # end

      print "\n"
    end
  end
end

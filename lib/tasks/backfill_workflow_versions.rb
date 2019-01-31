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

      puts "Loading workflow versions"
      workflow_versions = workflow.versions.pluck(:id)[1..-1]
      puts "Loading workflow content versions"
      workflow_content_versions = workflow_content.versions.pluck(:id)[1..-1]

      puts "Loaded #{workflow_versions.size} workflow versions, #{workflow_content_versions.size} workflow content versions"

      puts "Finding which versions are in use"
      used_versions = Standby.on_standby do
        Classification.where(workflow_id: workflow.id).select(:workflow_version).distinct.map(&:workflow_version)
      end

      puts "Backfilling #{used_versions.size} versions"
      used_versions.each do |used_version|
        puts used_version
        workflow_index, workflow_content_index = used_version.split(".").map(&:to_i)

        workflow_at_version = if workflow_index >= workflow_versions.size
                                # latest workflow, no version
                                workflow
                              else
                                workflow.versions.find(workflow_versions[workflow_index - 1]).reify
                              end

        workflow_content_at_version = if workflow_content_index >= workflow_content_versions.size
                                        # latest content, no version
                                        workflow_content
                                      else
                                        workflow_content.versions.find(workflow_content_versions[workflow_content_index - 1]).reify
                                      end

        backfill_version(workflow, workflow_index - 1, workflow_content_index - 1, workflow_at_version, workflow_content_at_version)
      end

      # Initially migration started using simply the code below. The workflows with IDs < 1860(ish) were migrated
      # in this fashion, and so you'll find that these have a lot more versions attached to them, whereas the code above
      # is much more limited and only creates WorkflowVersion records for those versions that were actually used in a
      # classification.
      #
      # workflow_versions.each_with_index do |workflow_at_version, w_index|
      #   workflow_content_versions.each_with_index do |workflow_content_at_version, wc_index|
      #     backfill_version(workflow, w_index, wc_index, workflow_at_version, workflow_content_at_version)
      #   end
      # end

      print "\n"
    end
  end
end

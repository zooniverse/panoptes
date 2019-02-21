# lib/backfill_project_versions.rb
module Tasks
  class BackfillProjectVersions
    def backfill_version(project, project_at_version, project_content_at_version)
      timestamp = [project_at_version.updated_at, project_content_at_version.updated_at].max

      project_version = ProjectVersion.new(project_id: project.id)
      project_version.private = project_at_version.private
      project_version.live = project_at_version.live
      project_version.beta_requested = project_at_version.beta_requested
      project_version.beta_approved = project_at_version.beta_approved
      project_version.launch_requested = project_at_version.launch_requested
      project_version.launch_approved = project_at_version.launch_approved
      project_version.display_name = project_at_version.display_name
      project_version.description = project_content_at_version.description
      project_version.workflow_description = project_content_at_version.workflow_description
      project_version.introduction = project_content_at_version.introduction
      project_version.url_labels = project_content_at_version.url_labels
      project_version.researcher_quote = project_content_at_version.researcher_quote
      project_version.updated_at = timestamp
      project_version.save!
      print '.'
    end

    def backfill(project)
      project.project_versions.where("created_at IS NOT NULL").delete_all

      project_content = project.primary_content

      # It is hard to figure out which combinations of major/minor actually
      # existed. For now I'm opting to simply generate all permutations.
      # I'd love to have a discussion on how to do this more wisely.
      #
      puts "Loading project versions"
      project_versions = (project.versions[1..-1] || []).map(&:reify) + [project]
      puts "Loading project content versions"
      project_content_versions = project_content.versions[1..-1].map(&:reify) + [project_content]

      puts "Loaded #{project_versions.size} project versions, #{project_content_versions.size} project content versions"

      project_versions.each_with_index do |project_at_version, idx|
        content_at_version = project_content_versions.select { |i| i.updated_at < project_at_version.updated_at }.last
        content_at_version ||= project_content_versions.first
        print 'P'
        backfill_version(project, project_at_version, content_at_version)

        content_versions = project_content_versions.select do |i|
          next_project_version = project_versions[idx+1]

          if next_project_version
            # use only content versions up till the next project version
            i.updated_at >= project_at_version.updated_at && i.updated_at < next_project_version.updated_at
          else
            # no further project version, so use all content versions beyond this timestamp
            i.updated_at >= project_at_version.updated_at
          end
        end

        content_versions.each do |content_at_version|
          print 'c'
          backfill_version(project, project_at_version, content_at_version)
        end
      end

      print "\n"
    end
  end
end

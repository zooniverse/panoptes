class ProjectCopier
  EXCLUDE_ATTRIBUTES = [:classifications_count, :launched_row_order, :beta_row_order].freeze
  INCLUDE_ASSOCIATIONS = [:tutorials,
                          :field_guides,
                          :pages,
                          :tags,
                          :tagged_resources,
                          :avatar,
                          :background,
                          :translations,
                          {active_workflows: [:tutorials, :attached_images]}].freeze

  def self.copy(project_id, user_id)
    project = Project.find(project_id)
    user = User.find(user_id)

    copied_project = project.deep_clone include: INCLUDE_ASSOCIATIONS, except: EXCLUDE_ATTRIBUTES
    copied_project.owner = user

    if user == project.owner
      copied_project.display_name += " (copy)"
    end

    copied_project.assign_attributes(launch_approved: false, live: false)
    # reset the project's configuration but record the source project id
    copied_project.configuration = { source_project_id: project.id }
    # reset the copied translations to not have any old string versions
    copied_project.translations.each { |tr| tr.string_versions = {} }

    Project.transaction(requires_new: true) do
      # save the project and create the project versions for use in translation strings
      copied_project.save!
      # update all the translation strings versions to match the latest project_version resource
      copied_project.translations.each do |translation|
        translated_strings = TranslationStrings.new(copied_project).extract
        translation.update_strings_and_versions(translated_strings, copied_project.latest_version_id)
        translation.save!
      end
    end
    copied_project
  end
end

class ProjectCopier
  EXCLUDE_ATTRIBUTES = [:classifications_count, :launched_row_order, :beta_row_order].freeze
  INCLUDE_ASSOCIATIONS = [:tutorials,
                          :field_guides,
                          :pages,
                          :tags,
                          :tagged_resources,
                          :avatar,
                          :background,
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

    # copy the translation resources from the source project
    # note they currently have the wrong version id as it relates to the source project
    copied_translations = project.translations.map(&:dup)

    Project.transaction(requires_new: true) do
      # save the project and create the project versions for use in translation strings
      copied_project.save!

      # update all the translation strings versions to match the latest project_version resource
      translation_strings_version_id = copied_project.latest_version_id
      copied_translations.map do |translation|
        # do not touch the translated strings
        # instead only update string versions to the latest_version_id of the copied workflow resource
        translation.string_versions.transform_values! { |_v| translation_strings_version_id }
      end
      # persist the translations association
      copied_project.translations = copied_translations
    end
    copied_project
  end
end

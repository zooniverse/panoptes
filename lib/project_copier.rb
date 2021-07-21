class ProjectCopier
  attr_reader :project_to_copy, :user

  EXCLUDE_ATTRIBUTES = %i[classifications_count launched_row_order beta_row_order].freeze
  INCLUDE_ASSOCIATIONS = [
    :tutorials,
    :field_guides,
    :pages,
    :tags,
    :tagged_resources,
    :avatar,
    :background,
    { active_workflows: %i[tutorials attached_images] }
  ].freeze

  def initialize(project_id, user_id)
    @project_to_copy = Project.find(project_id)
    @user = User.find(user_id)
  end

  def copy
    copied_project = copy_project


    # Note for the newly copied project relations
    # the below syncs the primary language translation strings
    # but it doesn't copy the associated resource's translations
    # long term we may want to ensure these are copied as well
    #
    # active_workflows and their tutorials
    # copied_project.active_workflows.each do |workflow|
    #   TranslationSyncWorker.new.perform(workflow.class.name, workflow.id, workflow.translatable_language)
    #   wf.tutorials.each do |tutorial|
    #     TranslationSyncWorker.new.perform(tutorial.class.name, tutorial.id, tutorial.translatable_language)
    #   end
    # end
    # # project field_guides
    # copied_project.field_guides.each do |field_guide|
    #   TranslationSyncWorker.new.perform(field_guide.class.name, field_guide.id, field_guide.translatable_language)
    # end
    # # project pages
    # copied_project.pages.each do |pages|
    #   TranslationSyncWorker.new.perform(pages.class.name, pages.id, pages.translatable_language)
    # end

    copied_project
  end

  private

  def copy_project
    copied_project = project_to_copy.deep_clone include: INCLUDE_ASSOCIATIONS, except: EXCLUDE_ATTRIBUTES
    copied_project.owner = user

    copied_project.display_name += ' (copy)' if user == project_to_copy.owner

    copied_project.assign_attributes(launch_approved: false, live: false)
    # reset the project's configuration but record the source project id
    copied_project.configuration = { source_project_id: project_to_copy.id }

    # sync the project translations
    sync_project_translations!(copied_project)

    # return the newly copied project
    copied_project
  end

  def sync_project_translations!(copied_project)
    # copy the translation resources from the source project
    # note they currently have the wrong version id as it relates to the source project
    copied_translations = project_to_copy.translations.map(&:dup)

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
  end
end

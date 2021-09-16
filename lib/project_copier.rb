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
    # Should this all be wrapped in a transaction?
    # to ensure we rollback an sub resource creations,
    # e.g. inband primary lang strings for the associated resources....
    Project.transaction(requires_new: true) do
      copied_project = copy_project

      # save the project and create the project versions for use in translation strings
      copied_project.save!

      # sync and persist the project translation associations
      copied_project.translations = copy_project_translations(copied_project)

      # sync the associated resources primary language translations
      # to keep the translations system working with these copied resources
      setup_associated_primary_language_translations(copied_project)

      # return the newly copied project
      copied_project
    end
  end

  private

  def copy_project
    copied_project = project_to_copy.deep_clone include: INCLUDE_ASSOCIATIONS, except: EXCLUDE_ATTRIBUTES
    copied_project.owner = user

    copied_project.display_name += ' (copy)' if user == project_to_copy.owner

    copied_project.assign_attributes(launch_approved: false, live: false)
    # reset the project's configuration but record the source project id
    copied_project.configuration = { source_project_id: project_to_copy.id }

    # return the newly copied project
    copied_project
  end

  def copy_project_translations(copied_project)
    # copy the translation resources from the source project
    # note they currently have the wrong version id as it relates to the source project
    copied_translations = project_to_copy.translations.map(&:dup)

    # update all the translation strings versions to match the latest project_version resource
    translation_strings_version_id = copied_project.latest_version_id
    copied_translations.map do |translation|
      # do not touch the translated strings
      # instead only update string versions to the latest_version_id of the copied workflow resource
      translation.string_versions.transform_values! { |_v| translation_strings_version_id }
    end

    copied_translations
  end

  # setup the associated primary language translations
  # e.g. project.pages, project.field_guides, project.active_workflows
  #
  # Note for the newly copied project relations
  # translations.zooniverse.org need the primary language translation strings
  # however this approach this does not copy the undlerying resource translations :( yet...
  # e.g. project.active_workflows.translations are not copied with each active_workflow
  #
  # long term we may want to ensure these translation resources are copied as well
  # (perhaps by re-using the workflow copier class?)
  # but short term this approach will ensure the translations app can work
  # and we can revisit code once / if this is being actively used by project teams
  # and they need the translations to be copied as well (i.e. a fully translated template project)
  def setup_associated_primary_language_translations(copied_project)
    # active_workflows
    copied_project.active_workflows.each do |workflow|
      sync_association_translations(workflow)
      # and sync their tutorials
      workflow.tutorials.each do |tutorial|
        sync_association_translations(tutorial)
      end
    end

    # project field_guides
    copied_project.field_guides.each do |field_guide|
      sync_association_translations(field_guide)
    end

    # project pages
    copied_project.pages.each do |page|
      sync_association_translations(page)
    end
  end

  def sync_association_translations(association_resource)
    # if needed this can be moved to async worker
    TranslationSyncWorker.new.perform(
      association_resource.class.name,
      association_resource.id,
      association_resource.translatable_language
    )
  end
end

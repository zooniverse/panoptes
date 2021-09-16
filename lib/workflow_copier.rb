# frozen_string_literal: true

class WorkflowCopier
  EXCLUDE_ATTRIBUTES = %i[
    classifications_count
    completeness
    published_version_id
    real_set_member_subjects_count
    retired_set_member_subjects_count
    finished_at
  ].freeze

  def self.copy_by_id(workflow_id, target_project_id)
    source_workflow = Workflow.find(workflow_id)
    copy(source_workflow, target_project_id)
  end

  def self.copy(source_workflow, target_project_id)
    copied_workflow = source_workflow.deep_clone(except: EXCLUDE_ATTRIBUTES)
    copied_workflow.project_id = target_project_id
    copied_workflow.active = false
    copied_workflow.display_name = "#{copied_workflow.display_name} (copy: #{Time.now.utc})"
    copied_workflow.configuration['source_workflow_id'] = source_workflow.id
    copied_workflow.current_version_number = nil
    copied_workflow.major_version = 0
    copied_workflow.minor_version = 0

    # copy the translation resources from the source workflow
    # note they currently have the wrong version id as it relates to the source workflow
    copied_translations = source_workflow.translations.map(&:dup)

    Workflow.transaction(requires_new: true) do
      # save the workflow and create the workflow versions for use in translation strings
      copied_workflow.save!
      # update all the translation strings versions to match the latest workflow_version resource
      translation_strings_version_id = copied_workflow.latest_version_id
      copied_translations.map do |translation|
        # do not touch the translated strings
        # instead only update string versions to the latest_version_id of the copied workflow resource
        translation.string_versions.transform_values! { |_v| translation_strings_version_id }
      end
      # persist the translations association
      copied_workflow.translations = copied_translations
    end

    copied_workflow
  end
end

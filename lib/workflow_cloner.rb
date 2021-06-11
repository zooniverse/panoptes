# frozen_string_literal: true

class WorkflowCloner
  EXCLUDE_ATTRIBUTES = %i[published_version_id].freeze

  # deep copy a workflow resource but don't save it
  # similar behaviour to AR `.dup` method
  def self.dup(workflow_id, target_project_id)
    source_workflow = Workflow.find(workflow_id)

    copied_workflow = source_workflow.deep_clone except: EXCLUDE_ATTRIBUTES
    copied_workflow.project_id = target_project_id
    copied_workflow.active = false
    copied_workflow.display_name = "#{copied_workflow.display_name} (copy: #{Time.now.utc})"
    copied_workflow.configuration['source_workflow_id'] = workflow_id
    copied_workflow
  end
end

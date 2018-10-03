class WorkflowVersion < ActiveRecord::Base
  belongs_to :workflow

  def self.build_from(workflow)
    version = new
    version.major_version = workflow.major_version
    version.minor_version = workflow.minor_version
    version.workflow_id = workflow.id
    version.tasks = workflow.tasks
    version.first_task = workflow.first_task
    version.strings = workflow.strings
    version
  end

  def self.create_from(workflow)
    version = build_from(workflow)
    version.save!
    version
  end
end

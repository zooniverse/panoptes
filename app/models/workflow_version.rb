class WorkflowVersion < ActiveRecord::Base
  belongs_to :workflow

  has_many :workflow_content_versions
  belongs_to :primary_content, class_name: "WorkflowContentVersion"

  def self.build_from(workflow)
    version = new
    version.workflow_id = workflow.id
    version.tasks = workflow.tasks
    version.first_task = workflow.first_task

    workflow.workflow_contents.find_each do |workflow_content|
      content_version = WorkflowContentVersion.build_from(workflow_content)
      version.workflow_content_versions << content_version
      version.primary_content = content_version if workflow.primary_content.language == content_version.language
    end

    version
  end

  def self.create_from(workflow)
    version = build_from(workflow)
    transaction do
      version.save!
      version.workflow_content_versions.each(&:save!)
    end

    version
  end
end

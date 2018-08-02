class WorkflowContentVersion < ActiveRecord::Base
  belongs_to :workflow_version
  belongs_to :workflow_content

  def self.build_from(workflow_content)
    version = new
    version.workflow_content_id = workflow_content.id
    version.language = workflow_content.language
    version.strings = workflow_content.strings
    version
  end
end

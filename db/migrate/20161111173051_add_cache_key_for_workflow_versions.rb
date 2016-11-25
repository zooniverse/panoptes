class AddCacheKeyForWorkflowVersions < ActiveRecord::Migration
  def change
    Workflow.where(current_version_number: nil).find_each do |w|
      w.send(:update_workflow_version_cache)
    end

    WorkflowContent.where(current_version_number: nil).find_each do |wc|
      wc.send(:update_workflow_version_cache)
    end
  end
end

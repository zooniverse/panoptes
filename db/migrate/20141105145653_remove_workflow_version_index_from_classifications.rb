class RemoveWorkflowVersionIndexFromClassifications < ActiveRecord::Migration
  def change
    remove_index :classifications, :workflow_version_id
  end
end

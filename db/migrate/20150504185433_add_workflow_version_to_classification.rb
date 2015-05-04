class AddWorkflowVersionToClassification < ActiveRecord::Migration
  def change
    add_column :classifications, :workflow_version, :text
    Classification.update_all("workflow_version = metadata->>'workflow_version'")
    add_index :classifications, :workflow_version
  end
end

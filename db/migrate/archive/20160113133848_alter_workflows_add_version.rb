class AlterWorkflowsAddVersion < ActiveRecord::Migration
  def change
    add_column :workflows, :current_version_number, :string
    add_column :workflow_contents, :current_version_number, :string
  end
end

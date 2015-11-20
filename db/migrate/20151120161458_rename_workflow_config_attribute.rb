class RenameWorkflowConfigAttribute < ActiveRecord::Migration
  def change
    rename_column :workflows, :config, :configuration
  end
end

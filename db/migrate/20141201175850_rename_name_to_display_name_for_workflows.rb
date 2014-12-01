class RenameNameToDisplayNameForWorkflows < ActiveRecord::Migration
  def change
    rename_column :workflows, :name, :display_name
  end
end

class UpdateProjectsDefaultsAndIndexes < ActiveRecord::Migration
  def up
    change_column :projects, :approved, :boolean, default: false
    add_index :projects, :approved
    change_column :projects, :beta, :boolean, default: false
    add_index :projects, :beta
  end

  def down
    change_column :projects, :approved, :boolean, default: nil
    change_column :projects, :beta, :boolean, default: nil
  end
end

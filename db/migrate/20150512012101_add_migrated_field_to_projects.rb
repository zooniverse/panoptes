class AddMigratedFieldToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :migrated, :boolean, default: false
    Project.update_all(migrated: false)
  end
end

class AddProjectVersionTimestamps < ActiveRecord::Migration
  def change
    add_index :project_versions, :project_id
    add_column :project_versions, :created_at, :timestamp
    add_column :project_versions, :updated_at, :timestamp
  end
end

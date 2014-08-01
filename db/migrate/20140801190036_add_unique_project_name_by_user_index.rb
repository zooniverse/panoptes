class AddUniqueProjectNameByUserIndex < ActiveRecord::Migration
  def change
    remove_index :projects, name: "index_projects_on_name"
    add_index :projects, [ "name" ], unique: false
    add_index :projects, [ "name", "owner_id", "owner_type"], unique: true
  end
end

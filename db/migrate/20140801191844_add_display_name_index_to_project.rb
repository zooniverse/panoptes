class AddDisplayNameIndexToProject < ActiveRecord::Migration
  def change
    add_index :projects, [ "display_name", "owner_id", "owner_type" ]
  end
end

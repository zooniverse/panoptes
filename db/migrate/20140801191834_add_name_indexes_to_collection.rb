class AddNameIndexesToCollection < ActiveRecord::Migration
  def change
    add_index :collections, [ "name", "owner_id", "owner_type" ], unique: true
    add_index :collections, [ "display_name", "owner_id", "owner_type" ], unique: true
  end
end

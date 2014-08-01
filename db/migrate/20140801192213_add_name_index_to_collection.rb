class AddNameIndexToCollection < ActiveRecord::Migration
  def change
    add_index :collections, [ "name" ], unique: false
  end
end

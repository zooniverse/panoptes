class AddDescriptionToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :description, :text
    Collection.update_all(description: "")
    change_column_default(:collections, :description, "")
  end
end

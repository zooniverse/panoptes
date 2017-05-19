class AddDescriptionToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :description, :text, default: ""
    Collection.update_all(display_name: "")
  end
end

class AddDisplayNameToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :display_name, :string
  end
end

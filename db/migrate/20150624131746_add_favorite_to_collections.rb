class AddFavoriteToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :favorite, :boolean, default: false, null: false
    add_index :collections, :favorite
  end
end

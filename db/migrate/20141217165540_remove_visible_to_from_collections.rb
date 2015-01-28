class RemoveVisibleToFromCollections < ActiveRecord::Migration
  def change
    remove_column :collections, :visible_to, :string
  end
end

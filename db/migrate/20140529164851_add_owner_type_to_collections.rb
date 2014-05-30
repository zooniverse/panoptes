class AddOwnerTypeToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :owner_type, :string
  end
end

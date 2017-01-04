class AddCollectionDisplayNameIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :collections, :display_name, algorithm: :concurrently
  end
end

class AddMediaLinkedIdIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :media, :linked_id, algorithm: :concurrently
  end
end

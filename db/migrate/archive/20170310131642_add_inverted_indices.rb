class AddInvertedIndices < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :media, [:linked_id, :linked_type], algorithm: :concurrently
    add_index :tagged_resources, [:resource_id, :resource_type], algorithm: :concurrently
  end
end

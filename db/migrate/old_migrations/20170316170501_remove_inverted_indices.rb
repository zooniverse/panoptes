class RemoveInvertedIndices < ActiveRecord::Migration
  def change
    remove_index :media, column: [:linked_type, :linked_id]
    remove_index :tagged_resources, column: [:resource_type, :resource_id]
  end
end

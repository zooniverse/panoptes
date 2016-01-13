class RemoveClassificationIndexes < ActiveRecord::Migration
  def change
    #don't revert these, add a new migration and build the indexes concurrently!
    remove_index :classifications, column: :created_at
    remove_index :classifications, column: :lifecycled_at
  end
end

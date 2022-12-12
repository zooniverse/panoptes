class SparseIndexUpdates < ActiveRecord::Migration
  def change
    remove_index :users, column: :ouroboros_created
    remove_index :workflows, column: :active
  end
end

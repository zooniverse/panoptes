class RemoveClassificationIndexesAgain < ActiveRecord::Migration
  def change
    remove_index :classifications, column: :created_at
    remove_index :classifications, column: :gold_standard
  end
end

class AddAggregatesUniqueIndex < ActiveRecord::Migration
  def change
    add_index :aggregations, [:subject_id, :workflow_id], unique: true
  end
end

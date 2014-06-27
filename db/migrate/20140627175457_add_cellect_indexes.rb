class AddCellectIndexes < ActiveRecord::Migration
  def change
    add_index :user_seen_subjects, [:user_id, :workflow_id]
  end
end

class MakeUssIndexUnique < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    remove_index :user_seen_subjects, column: [:user_id, :workflow_id]
    add_index :user_seen_subjects, [:user_id, :workflow_id], unique: true
  end
end

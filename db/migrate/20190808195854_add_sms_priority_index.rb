class AddSmsPriorityIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :set_member_subjects, [:subject_set_id, :priority], unique: true, algorithm: :concurrently
  end
end

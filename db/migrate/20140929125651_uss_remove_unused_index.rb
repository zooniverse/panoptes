class UssRemoveUnusedIndex < ActiveRecord::Migration
  def change
    remove_index :user_seen_subjects, column: :user_id
  end
end

class RecentsIndexUpdates < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    %i(classification_id project_id subject_id user_id workflow_id).each do |col|
      remove_index :recents, column: col
      add_index :recents, col, algorithm: :concurrently
    end

    add_index :recents, :created_at, algorithm: :concurrently
  end
end

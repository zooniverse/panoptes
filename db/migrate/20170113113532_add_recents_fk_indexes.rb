class AddRecentsFkIndexes < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    %i(project_id workflow_id user_id).each do |col|
      add_index :recents, col, algorithm: :concurrently
    end
  end
end

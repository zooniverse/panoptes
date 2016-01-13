class DedupeUpps < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    UserProjectPreference.connection.execute <<-SQL
      DELETE FROM user_project_preferences
      WHERE id IN (
        SELECT id
        FROM (
          SELECT id, ROW_NUMBER() OVER (PARTITION BY user_id, project_id ORDER BY id ASC) AS row
          FROM user_project_preferences
        ) dupes
        WHERE dupes.row > 1
      );
    SQL

    add_index :user_project_preferences, [:user_id, :project_id], unique: true, algorithm: :concurrently
  end
end

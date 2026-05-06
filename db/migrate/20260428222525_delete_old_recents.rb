class DeleteOldRecents < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    safety_assured do
      cutoff_date = 14.days.ago.to_fs(:db)
      current_time = Time.current.to_fs(:db)

      say "Step 1: Creating new table from existing and loading recent recents..."

      execute <<-SQL
        CREATE TABLE recents_new (LIKE recents INCLUDING DEFAULTS INCLUDING CONSTRAINTS);

        INSERT INTO recents_new
        SELECT * FROM recents
        WHERE created_at >= '#{cutoff_date}'
          AND created_at < '#{current_time}';
      SQL

      say "Step 2: Building indexes and FKs on new table with temporary names..."

      execute "ALTER TABLE recents_new ADD PRIMARY KEY (id);"

      execute "CREATE INDEX index_recents_new_on_workflow_id ON recents_new (workflow_id);"
      execute "CREATE INDEX index_recents_new_on_project_id ON recents_new (project_id);"
      execute "CREATE INDEX index_recents_new_on_user_id ON recents_new (user_id);"
      execute "CREATE INDEX index_recents_new_on_subject_id ON recents_new (subject_id);"
      execute "CREATE INDEX index_recents_new_on_created_at ON recents_new (created_at);"

      # New compound index for user/created_at lookups
      execute "CREATE INDEX index_recents_on_user_and_created ON recents_new (user_id, created_at DESC);"

      execute <<-SQL
        ALTER TABLE recents_new
        ADD CONSTRAINT fk_recents_classifications
        FOREIGN KEY (classification_id) REFERENCES classifications(id);

        ALTER TABLE recents_new
        ADD CONSTRAINT fk_recents_subjects
        FOREIGN KEY (subject_id) REFERENCES subjects(id);
      SQL

      say "Step 3: Executing the table swap..."

      execute <<-SQL
        BEGIN;

        -- Lock table prevent incoming writes
        LOCK TABLE recents IN ACCESS EXCLUSIVE MODE;

        -- Catch up any records created during above operations
        INSERT INTO recents_new
        SELECT * FROM recents
        WHERE created_at >= '#{current_time}';

        -- Swap the tables
        ALTER TABLE recents RENAME TO recents_old;
        ALTER TABLE recents_new RENAME TO recents;

        -- Clean up index names so structure.sql looks untouched
        ALTER INDEX recents_pkey RENAME TO recents_old_pkey;
        ALTER INDEX recents_new_pkey RENAME TO recents_pkey;

        ALTER INDEX index_recents_on_workflow_id RENAME TO index_recents_old_on_workflow_id;
        ALTER INDEX index_recents_new_on_workflow_id RENAME TO index_recents_on_workflow_id;

        ALTER INDEX index_recents_on_project_id RENAME TO index_recents_old_on_project_id;
        ALTER INDEX index_recents_new_on_project_id RENAME TO index_recents_on_project_id;

        ALTER INDEX index_recents_on_user_id RENAME TO index_recents_old_on_user_id;
        ALTER INDEX index_recents_new_on_user_id RENAME TO index_recents_on_user_id;

        ALTER INDEX index_recents_on_subject_id RENAME TO index_recents_old_on_subject_id;
        ALTER INDEX index_recents_new_on_subject_id RENAME TO index_recents_on_subject_id;

        ALTER INDEX index_recents_on_created_at RENAME TO index_recents_old_on_created_at;
        ALTER INDEX index_recents_new_on_created_at RENAME TO index_recents_on_created_at;

        -- Transfer sequence ownership
        ALTER SEQUENCE recents_id_seq OWNED BY recents.id;

        COMMIT;
      SQL

      say "Step 4: Updating database statistics for the new table..."
      execute "ANALYZE recents;"

      say "Recents swap complete."
    end
  end

  def down
    safety_assured do
      execute <<-SQL
        BEGIN;
        LOCK TABLE recents IN ACCESS EXCLUSIVE MODE;

        -- Swap tables back
        ALTER TABLE recents RENAME TO recents_new;
        ALTER TABLE recents_old RENAME TO recents;

        -- Revert Sequence
        ALTER SEQUENCE recents_id_seq OWNED BY recents.id;

        -- Revert index names to original state
        ALTER INDEX recents_pkey RENAME TO recents_new_pkey;
        ALTER INDEX recents_old_pkey RENAME TO recents_pkey;

        ALTER INDEX index_recents_on_workflow_id RENAME TO index_recents_new_on_workflow_id;
        ALTER INDEX index_recents_old_on_workflow_id RENAME TO index_recents_on_workflow_id;

        ALTER INDEX index_recents_on_project_id RENAME TO index_recents_new_on_project_id;
        ALTER INDEX index_recents_old_on_project_id RENAME TO index_recents_on_project_id;

        ALTER INDEX index_recents_on_user_id RENAME TO index_recents_new_on_user_id;
        ALTER INDEX index_recents_old_on_user_id RENAME TO index_recents_on_user_id;

        ALTER INDEX index_recents_on_subject_id RENAME TO index_recents_new_on_subject_id;
        ALTER INDEX index_recents_old_on_subject_id RENAME TO index_recents_on_subject_id;

        ALTER INDEX index_recents_on_created_at RENAME TO index_recents_new_on_created_at;
        ALTER INDEX index_recents_old_on_created_at RENAME TO index_recents_on_created_at;

        COMMIT;
      SQL

      execute "DROP TABLE recents_new;"
    end
  end
end
class CreateSqlTriggerToUpdateTsvVector < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    safety_assured {
      execute <<-SQL
        CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
        ON user_groups FOR EACH ROW EXECUTE PROCEDURE
        tsvector_update_trigger(
          tsv, 'pg_catalog.english', display_name
        );
      SQL
    }
  end

  def down
    safety_assured {
      execute <<-SQL
        DROP TRIGGER tsvectorupdate
        ON user_groups;
      SQL
    }
  end
end

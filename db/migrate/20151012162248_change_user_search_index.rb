class ChangeUserSearchIndex < ActiveRecord::Migration
  def up
    remove_index :users, name: "users_idx_trgm_login_display_name"
    add_column :users, :tsv, :tsvector

    add_index :users, :tsv, using: "gin"

    execute <<-SQL
      CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
      ON users FOR EACH ROW EXECUTE PROCEDURE
      tsvector_update_trigger(
        tsv, 'pg_catalog.english', login, display_name
      );
    SQL

    now = Time.current.to_s(:db)
    update("UPDATE users SET updated_at = '#{now}'")
  end

  def down
    execute <<-SQL
      DROP TRIGGER tsvectorupdate
      ON users
    SQL

    remove_index :users, :tsv
    remove_column :users, :tsv
  end
end

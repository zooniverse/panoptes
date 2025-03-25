class AddUserLoginTrigramIndex < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE INDEX users_idx_trgm_login_display_name ON users
      USING gin((coalesce("users"."login"::text, '') || ' ' || coalesce("users"."display_name"::text, '')) gin_trgm_ops);
      DROP TRIGGER tsvectorupdate ON users;

      CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
      ON users FOR EACH ROW EXECUTE PROCEDURE
      tsvector_update_trigger(
        tsv, 'pg_catalog.english', login, display_name
      );
    SQL
  end

  def down
    remove_index :users, name: "users_idx_trgm_login_display_name"
  end
end

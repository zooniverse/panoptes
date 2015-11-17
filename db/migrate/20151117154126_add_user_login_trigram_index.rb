class AddUserLoginTrigramIndex < ActiveRecord::Migration
  def up
    add_index :users, name: "users_idx_trgm_login_display_name", using: :gin, operator_class: :gin_trgm_ops,
      expression: %((coalesce("users"."login"::text, '') || ' ' || coalesce("users"."display_name"::text, '')) gin_trgm_ops)

    execute <<-SQL
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

class AddTrigramIndexToLogin < ActiveRecord::Migration
  def up
    remove_index :users, name: "users_display_name_trgm_index"
    execute <<-SQL
      CREATE INDEX users_idx_trgm_login_display_name ON users
      USING gin((coalesce("users"."login"::text, '') || ' ' || coalesce("users"."display_name"::text, '')) gin_trgm_ops);
    SQL
  end
end

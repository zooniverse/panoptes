class AddUniqNamingIndexes < ActiveRecord::Migration
  def change
    add_index :user_groups, :display_name, unique: true
    execute "CREATE UNIQUE INDEX index_users_on_lowercase_login " +
             "ON users USING btree (lower(login));"
    execute "CREATE UNIQUE INDEX index_user_groups_on_lowercase_display_name " +
             "ON user_groups USING btree (lower(display_name));"
  end

  def down
    execute "DROP INDEX index_users_on_lowercase_login"
    execute "DROP INDEX index_user_groups_on_lowercase_display_name"
  end
end

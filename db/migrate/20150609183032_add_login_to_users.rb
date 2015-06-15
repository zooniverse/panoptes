class AddLoginToUsers < ActiveRecord::Migration
  def up
    add_column :users, :login, :string

    execute 'create unique index index_users_on_lowercase_login on users using btree (lower(login));'
    execute 'create unique index index_users_on_lowercase_display_name on users using btree (lower(display_name));'
  end

  def down
    execute "drop index index_users_on_lowercase_login;"
    execute "drop index index_users_on_lowercase_display_name;"
    execute 'drop index index_users_on_lowercase_email;'
    remove_column :users, :login
  end
end

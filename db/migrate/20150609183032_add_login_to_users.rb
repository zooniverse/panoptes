class AddLoginToUsers < ActiveRecord::Migration
  def up
    add_column :users, :login, :string
    remove_index :users, :email

    execute 'create unique index index_users_on_lowercase_login on users using btree (lower(login));'
    execute 'create unique index index_users_on_lowercase_display_name on users using btree (lower(display_name));'
    execute 'create unique index index_users_on_lowercase_email on users using btree (lower(email));'
  end

  def down
    execute "drop index index_users_on_lowercase_login;"
    execute "drop index index_users_on_lowercase_display_name;"
    execute 'drop index index_users_on_lowercase_email;'
    add_index :users, :email, unique: true
    remove_column :users, :login
  end
end

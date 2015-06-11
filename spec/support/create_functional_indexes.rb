class CreateFunctionalIndexes < ActiveRecord::Migration
  def up
    execute 'create unique index index_users_on_lowercase_login on users using btree (lower(login));'
    execute 'create unique index index_users_on_lowercase_display_name on users using btree (lower(display_name));'
    execute 'create unique index index_users_on_lowercase_email on users using btree (lower(email));'
    execute 'create unique index index_user_groups_on_lowercase_name on user_groups using btree (lower(name));'
  end

  def down
    execute "drop index index_users_on_lowercase_login;"
    execute "drop index index_users_on_lowercase_display_name;"
    execute 'drop index index_users_on_lowercase_email;'
    execute 'drop index index_user_groups_on_lowercase_name;'
  end
end

class AddLowercaseNameIndexToUserGroups < ActiveRecord::Migration
  def up
    remove_index :user_groups, :name
    remove_index :user_groups, :display_name
    execute 'create unique index index_user_groups_on_lowercase_name on user_groups using btree (lower(name));'
  end

  def down
    execute 'drop index index_user_groups_on_lowercase_name;'
    add_index :user_groups, :name, unique: true
    add_index :user_groups, :display_name, unique: true
  end
end

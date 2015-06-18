class AddLowercaseNameIndexToUserGroups < ActiveRecord::Migration
  def up
    remove_index :user_groups, :name
    remove_index :user_groups, :display_name
    add_index    :user_groups, :name, unique: true, case_sensitive: false
  end

  def down
    remove_index :user_groups, :name
    add_index    :user_groups, :name, unique: true
    add_index    :user_groups, :display_name, unique: true
  end
end

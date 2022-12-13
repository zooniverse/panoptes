class AddLoginToUsers < ActiveRecord::Migration
  def up
    remove_index :users, :display_name
    add_column :users, :login, :string
    add_index  :users, :login, unique: true, case_sensitive: false
    add_index  :users, :display_name, unique: true, case_sensitive: false
  end

  def down
    remove_index  :users, :display_name
    remove_column :users, :login
    add_index     :users, :display_name, unique: true, case_sensitive: false
  end
end

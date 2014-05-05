class AddUniqueIndexToLoginForUser < ActiveRecord::Migration
  def up
    remove_index :users, :login
    add_index :users, :login, unique: true
  end
  
  def down
    remove_index :users, :login
    add_index :users, :login
  end
end

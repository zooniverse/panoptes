class AddUsersDisplayNameIndex < ActiveRecord::Migration
  def change
    add_index :users, :display_name, unique: true
  end
end

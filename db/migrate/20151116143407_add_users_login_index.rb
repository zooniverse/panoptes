class AddUsersLoginIndex < ActiveRecord::Migration
  def change
    add_index :users, :login, unique: true, name: "index_users_on_login_with_case"
  end
end

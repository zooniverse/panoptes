class AddLowerIndexToUsersEmail < ActiveRecord::Migration
  def change
    add_index :users, :email, name: "index_users_on_lowercase_email",
     unique: true, case_sensitive: false
  end
end

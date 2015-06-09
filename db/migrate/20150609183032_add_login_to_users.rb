class AddLoginToUsers < ActiveRecord::Migration
  def change
    add_column :users, :login, :string, null: false
    add_index :users, :login, unique: true
  end
end

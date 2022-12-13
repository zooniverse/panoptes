class RemoveLoginAndGroupName < ActiveRecord::Migration
  def change
    remove_column :users, :login, :string, null: false
    add_index :user_groups, :display_name, unique: true
  end
end

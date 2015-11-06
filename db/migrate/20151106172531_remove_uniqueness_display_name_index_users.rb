class RemoveUniquenessDisplayNameIndexUsers < ActiveRecord::Migration
  def change
    remove_index :users, column: :display_name, unique: true
    add_index :users, :display_name
  end
end

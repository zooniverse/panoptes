class AddZooniverseIdIndexToUsers < ActiveRecord::Migration
  def change
    if index_exists?(:users, :zooniverse_id)
      remove_index :users, column: :zooniverse_id
    end
    add_index :users, :zooniverse_id, unique: true
  end
end

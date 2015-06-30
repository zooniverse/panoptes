class AddZooniverseIdIndexToUsers < ActiveRecord::Migration
  def change
    add_index :users, :zooniverse_id, unique: true
  end
end

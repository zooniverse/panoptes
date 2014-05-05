class AddZooniverseIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :zooniverse_id, :string
  end
end

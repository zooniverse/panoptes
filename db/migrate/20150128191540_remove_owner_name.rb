class RemoveOwnerName < ActiveRecord::Migration
  def change
    drop_table :owner_names
  end
end

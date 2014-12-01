class AddBannedFlagToUser < ActiveRecord::Migration
  def change
    add_column :users, :banned, :boolean, default: false, null: false
  end
end

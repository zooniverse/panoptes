class AddMigratedToUser < ActiveRecord::Migration
  def change
    add_column :users, :migrated, :boolean, default: false
  end
end

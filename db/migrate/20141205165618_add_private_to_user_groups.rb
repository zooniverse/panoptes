class AddPrivateToUserGroups < ActiveRecord::Migration
  def change
    add_column :user_groups, :private, :boolean, default: true, null: false
  end
end

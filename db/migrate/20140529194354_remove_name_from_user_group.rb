class RemoveNameFromUserGroup < ActiveRecord::Migration
  def change
    remove_column :user_groups, :name, :string
  end
end

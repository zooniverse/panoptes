class AddJoinTokenToUserGroups < ActiveRecord::Migration
  def change
    add_column :user_groups, :join_token, :string
  end
end

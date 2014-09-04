class AddClassificationsUserGroupIdIndex < ActiveRecord::Migration
  def change
    add_index :classifications, :user_group_id
  end
end

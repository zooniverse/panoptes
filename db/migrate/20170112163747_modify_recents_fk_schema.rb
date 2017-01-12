class ModifyRecentsFkSchema < ActiveRecord::Migration
  def change
    add_column :recents, :project_id, :integer, index: true
    add_column :recents, :workflow_id, :integer, index: true
    add_column :recents, :user_id, :integer, index: true
    add_column :recents, :user_group_id, :integer
  end
end

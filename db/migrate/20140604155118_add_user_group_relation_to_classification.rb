class AddUserGroupRelationToClassification < ActiveRecord::Migration
  def change
    add_column :classifications, :user_group_id, :integer
    add_column :user_groups, :classifications_count, :integer, default: 0, null: false
  end
end
